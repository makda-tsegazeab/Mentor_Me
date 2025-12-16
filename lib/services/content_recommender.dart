import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Pure client-side content-based recommender.
/// Reimplements the same logic as offline_recommender.py but runs in Flutter.
class ContentRecommender {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ------------- small helpers -------------

  static double _clamp01(double x) {
    if (x < 0) return 0;
    if (x > 1) return 1;
    return x;
  }

  static int _safeInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static List<String> _stringList(dynamic v) {
    if (v == null) return <String>[];
    if (v is List) {
      return v.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  // ---------- learner → tutor score ----------

  static double _priceScoreLearnerTutor(dynamic learnerMax, dynamic tutorMin) {
    if (learnerMax == null || tutorMin == null) return 1.0;

    final l = double.tryParse(learnerMax.toString());
    final t = double.tryParse(tutorMin.toString());
    if (l == null || t == null || l <= 0) return 1.0;

    if (t <= l) return 1.0;

    final diff = t - l;
    final penalty = _clamp01(diff / l);
    return 1.0 - penalty;
  }

  static double _capacityScoreLearnerTutor(
      dynamic learnerVal, dynamic tutorVal) {
    if (learnerVal == null) return 1.0;
    final l = _safeInt(learnerVal);
    if (l <= 0) return 1.0;

    final t = _safeInt(tutorVal);
    if (t <= 0) return 0.0;

    if (t >= l) return 1.0;
    return _clamp01(t / l);
  }

  static double _genderScoreLearner(dynamic pref, dynamic tutorSex) {
    if (pref == null) return 1.0;
    final p = pref.toString();
    if (p.isEmpty || p == 'no preference') return 1.0;
    if (tutorSex == null) return 0.0;
    return p == tutorSex.toString() ? 1.0 : 0.0;
  }

  static double _matchScoreLearnerTutor(
      Map<String, dynamic> learner, Map<String, dynamic> tutor) {
    final components = <double>[];

    final lSubs = _stringList(learner['subjects']).toSet();
    final tSubs = _stringList(tutor['subjects']).toSet();
    if (lSubs.isNotEmpty) {
      final overlap = lSubs.intersection(tSubs).length;
      components.add(overlap / lSubs.length);
    }

    final lGrades =
        _stringList(learner['gradeLevels'] ?? learner['grades']).toSet();
    final tGrades =
        _stringList(tutor['gradeLevels'] ?? tutor['grades']).toSet();
    if (lGrades.isNotEmpty) {
      final overlap = lGrades.intersection(tGrades).length;
      components.add(overlap / lGrades.length);
    }

    components.add(_priceScoreLearnerTutor(
        learner['maxPricePerHour'], tutor['minPricePerHour']));

    components.add(_capacityScoreLearnerTutor(
        learner['hoursPerDay'], tutor['hoursPerDay']));
    components.add(_capacityScoreLearnerTutor(
        learner['daysPerWeek'], tutor['daysPerWeek']));

    components.add(
        _genderScoreLearner(learner['preferredTutorGender'], tutor['sex']));

    if (components.isEmpty) return 0.0;
    final sum = components.fold<double>(0.0, (a, b) => a + b);
    return sum / components.length;
  }

  // ---------- tutor → learner score ----------

  static double _priceScoreTutorLearner(dynamic tutorMin, dynamic learnerMax) {
    if (tutorMin == null || learnerMax == null) return 1.0;

    final t = double.tryParse(tutorMin.toString());
    final m = double.tryParse(learnerMax.toString());
    if (t == null || m == null || t <= 0) return 1.0;

    if (m >= t) return 1.0;

    final deficit = (t - m) / t;
    return 1.0 - _clamp01(deficit);
  }

  static double _capacityScoreTutorLearner(
      dynamic tutorVal, dynamic learnerVal) {
    if (learnerVal == null) return 1.0;
    final l = _safeInt(learnerVal);
    if (l <= 0) return 1.0;

    final t = _safeInt(tutorVal);
    if (t <= 0) return 0.0;
    if (t >= l) return 1.0;

    return _clamp01(t / l);
  }

  static double _matchScoreTutorLearner(
      Map<String, dynamic> tutor, Map<String, dynamic> learner) {
    final components = <double>[];

    final lSubs = _stringList(learner['subjects']).toSet();
    final tSubs = _stringList(tutor['subjects']).toSet();
    if (lSubs.isNotEmpty) {
      final overlap = lSubs.intersection(tSubs).length;
      components.add(overlap / lSubs.length);
    }

    final lGrades =
        _stringList(learner['gradeLevels'] ?? learner['grades']).toSet();
    final tGrades =
        _stringList(tutor['gradeLevels'] ?? tutor['grades']).toSet();
    if (lGrades.isNotEmpty) {
      final overlap = lGrades.intersection(tGrades).length;
      components.add(overlap / lGrades.length);
    }

    components.add(_priceScoreTutorLearner(
        tutor['minPricePerHour'], learner['maxPricePerHour']));

    components.add(_capacityScoreTutorLearner(
        tutor['hoursPerDay'], learner['hoursPerDay']));
    components.add(_capacityScoreTutorLearner(
        tutor['daysPerWeek'], learner['daysPerWeek']));

    if (components.isEmpty) return 0.0;
    final sum = components.fold<double>(0.0, (a, b) => a + b);
    return sum / components.length;
  }

  // ---------- public API ----------

  /// Called from HomeScreen before you read the recommendations collection.
  /// It:
  ///  - looks at current user & role
  ///  - recomputes content-based recs for that user only
  ///  - writes to `recommendations/{learnerId}` or `tutor_recommendations/{tutorId}`.
  static Future<void> recomputeForCurrentUser() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await _db.collection('users').doc(user.uid).get();
    final data = snap.data();
    if (data == null) return;

    final role = data['role'] as String?;
    final completed = data['completedProfile'] == true;
    if (!completed || role == null) return;

    if (role == 'student' || role == 'parent') {
      await _recomputeForLearner(user.uid, data);
    } else if (role == 'tutor') {
      await _recomputeForTutor(user.uid, data);
    }
  }

  // ---------- learner side ----------

  static Future<void> _recomputeForLearner(
    String learnerId,
    Map<String, dynamic> learner,
  ) async {
    // all tutors with completedProfile == true & available == true
    final tutorsSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'tutor')
        .where('completedProfile', isEqualTo: true)
        .get();

    final List<Map<String, dynamic>> recs = [];

    for (final doc in tutorsSnap.docs) {
      final t = doc.data();
      if (t['available'] == false) continue;

      // (optional) city filter: comment out if you DON'T want same-city requirement
      final lc = (learner['city'] ?? '').toString().trim();
      final tc = (t['city'] ?? '').toString().trim();
      if (lc.isNotEmpty && tc.isNotEmpty && lc != tc) {
        continue;
      }

      final score = _matchScoreLearnerTutor(learner, t);
      if (score <= 0) continue;

      final subjects = _stringList(t['subjects']);
      final grades = _stringList(t['gradeLevels'] ?? t['grades']);

      final reasons = <String>[];
      if (subjects.isNotEmpty) {
        reasons.add('Teaches your subject(s): ${subjects.take(3).join(', ')}');
      }
      if (grades.isNotEmpty) {
        reasons.add('Covers your grade level(s): ${grades.take(3).join(', ')}');
      }

      recs.add({
        'tutorId': doc.id,
        'name': t['name'] ?? 'Tutor',
        'city': tc.isNotEmpty ? tc : 'Location not set',
        'subjects': subjects,
        'gradeLevels': grades,
        'minPricePerHour': t['minPricePerHour'],
        'profileImage': t['profileImage'],
        'score': score,
        'reasons': reasons,
      });
    }

    recs.sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));

    await _db.collection('recommendations').doc(learnerId).set({
      'items': recs,
      'updatedAt': FieldValue.serverTimestamp(),
      'source': 'content_client', // just for debugging
    });
  }

  // ---------- tutor side ----------

  static Future<void> _recomputeForTutor(
    String tutorId,
    Map<String, dynamic> tutor,
  ) async {
    final learnersSnap = await _db
        .collection('users')
        .where('role', whereIn: ['student', 'parent'])
        .where('completedProfile', isEqualTo: true)
        .get();

    final List<Map<String, dynamic>> recs = [];

    for (final doc in learnersSnap.docs) {
      final l = doc.data();

      // (optional) city filter same as above
      final tc = (tutor['city'] ?? '').toString().trim();
      final lc = (l['city'] ?? '').toString().trim();
      if (tc.isNotEmpty && lc.isNotEmpty && tc != lc) {
        continue;
      }

      final score = _matchScoreTutorLearner(tutor, l);
      if (score <= 0) continue;

      final subjects = _stringList(l['subjects']);
      final grades = _stringList(l['gradeLevels'] ?? l['grades']);

      final reasons = <String>[];
      if (subjects.isNotEmpty) {
        reasons.add('Wants your subject(s): ${subjects.take(3).join(', ')}');
      }
      if (grades.isNotEmpty) {
        reasons.add('Matches your grade levels: ${grades.take(3).join(', ')}');
      }

      recs.add({
        'learnerId': doc.id,
        'name': l['name'] ?? 'Learner',
        'city': lc.isNotEmpty ? lc : 'Location not set',
        'subjects': subjects,
        'gradeLevels': grades,
        'maxPricePerHour': l['maxPricePerHour'],
        'score': score,
        'reasons': reasons,
      });
    }

    recs.sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));

    await _db.collection('tutor_recommendations').doc(tutorId).set({
      'items': recs,
      'updatedAt': FieldValue.serverTimestamp(),
      'source': 'content_client',
    });
  }
}
