import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RatingProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<double> getTutorAverage(String tutorId) {
    return _db.collection('users').doc(tutorId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return 0.0;
      final avg = data['ratingAvg'];
      if (avg is num) return avg.toDouble();
      return 0.0;
    });
  }

  Stream<int> getTutorRatingCount(String tutorId) {
    return _db.collection('users').doc(tutorId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return 0;
      final cnt = data['ratingCount'];
      if (cnt is num) return cnt.toInt();
      return 0;
    });
  }

  Stream<Map<String, dynamic>?> getMyRating(String tutorId, String raterId) {
    return _db
        .collection('users')
        .doc(tutorId)
        .collection('ratings')
        .doc(raterId)
        .snapshots()
        .map((doc) => doc.data());
  }

  Future<void> submitRating({
    required String tutorId,
    required String raterId,
    required int score,
    String? comment,
    String? raterRole,
    String? relationshipId,
  }) async {
    assert(score >= 1 && score <= 5);
    final tutorRef = _db.collection('users').doc(tutorId);
    final ratingRef = tutorRef.collection('ratings').doc(raterId);

    await _db.runTransaction((tx) async {
      final ratingSnap = await tx.get(ratingRef);
      final tutorSnap = await tx.get(tutorRef);

      int ratingSum = 0;
      int ratingCount = 0;
      if (tutorSnap.exists) {
        final data = tutorSnap.data() as Map<String, dynamic>;
        final sum = data['ratingSum'];
        final cnt = data['ratingCount'];
        if (sum is num) ratingSum = sum.toInt();
        if (cnt is num) ratingCount = cnt.toInt();
      }

      if (ratingSnap.exists) {
        final old = ratingSnap.data() as Map<String, dynamic>;
        final oldScore = (old['score'] ?? 0) as int;
        ratingSum += (score - oldScore);
        tx.update(ratingRef, {
          'score': score,
          'comment': comment?.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        ratingSum += score;
        ratingCount += 1;
        tx.set(ratingRef, {
          'score': score,
          'comment': comment?.trim(),
          'raterId': raterId,
          'raterRole': raterRole,
          'relationshipId': relationshipId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final avg = ratingCount == 0 ? 0.0 : ratingSum / ratingCount;
      tx.set(
          tutorRef,
          {
            'ratingSum': ratingSum,
            'ratingCount': ratingCount,
            'ratingAvg': double.parse(avg.toStringAsFixed(2)),
            'rating': double.parse(avg.toStringAsFixed(2)),
          },
          SetOptions(merge: true));
    });

    notifyListeners();
  }
}
