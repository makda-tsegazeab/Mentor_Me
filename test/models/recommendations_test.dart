import 'package:flutter_test/flutter_test.dart';
import 'package:hey_tutor/models/recommendations.dart';

void main() {
  test('ContentTutorRec.fromMap parses list values', () {
    final rec = ContentTutorRec.fromMap({
      'tutorId': 't1',
      'score': 0.8,
      'name': 'Tutor',
      'city': 'Addis',
      'subjects': ['Math', 'Science'],
      'gradeLevels': ['9', '10'],
      'minPricePerHour': 15,
      'reasons': ['Reason'],
    });

    expect(rec.tutorId, 't1');
    expect(rec.score, 0.8);
    expect(rec.subjects, ['Math', 'Science']);
    expect(rec.gradeLevels, ['9', '10']);
    expect(rec.reasons, ['Reason']);
  });

  test('HybridTutorRec finalScore uses weighted logic', () {
    final both = HybridTutorRec(
      tutorId: 't1',
      contentScore: 0.6,
      mfScore: 0.9,
    );
    final contentOnly =
        HybridTutorRec(tutorId: 't2', contentScore: 0.4, mfScore: null);
    final mfOnly = HybridTutorRec(tutorId: 't3', mfScore: 0.7);

    expect(both.finalScore, closeTo(0.81, 0.0001));
    expect(contentOnly.finalScore, 0.4);
    expect(mfOnly.finalScore, 0.7);
  });

  test('HybridTutorRec copyWith merges fields', () {
    final base = HybridTutorRec(
      tutorId: 't1',
      contentScore: 0.2,
      mfScore: 0.3,
      name: 'Tutor',
      subjects: const ['Math'],
    );

    final updated = base.copyWith(
      mfScore: 0.9,
      subjects: const ['Science'],
    );

    expect(updated.tutorId, base.tutorId);
    expect(updated.contentScore, base.contentScore);
    expect(updated.mfScore, 0.9);
    expect(updated.subjects, const ['Science']);
  });

  test('TutorSideLearnerRec.fromMap handles values', () {
    final rec = TutorSideLearnerRec.fromMap({
      'learnerId': 'l1',
      'score': 0.55,
      'name': 'Learner',
      'subjects': ['English'],
      'gradeLevels': ['7'],
      'maxPricePerHour': 20,
      'reasons': ['Reason'],
    });

    expect(rec.learnerId, 'l1');
    expect(rec.score, 0.55);
    expect(rec.subjects, ['English']);
    expect(rec.gradeLevels, ['7']);
  });
}
