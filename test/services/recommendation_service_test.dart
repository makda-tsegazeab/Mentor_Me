import 'package:flutter_test/flutter_test.dart';
import 'package:hey_tutor/services/recommendation_service.dart';

class InMemoryRecommendationStore implements RecommendationStore {
  final Map<String, Map<String, Map<String, dynamic>>> _data;

  InMemoryRecommendationStore(this._data);

  @override
  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String docId,
  ) async {
    return _data[collection]?[docId];
  }
}

void main() {
  test('getHybridTutorRecommendationsForLearner merges and sorts', () async {
    final store = InMemoryRecommendationStore({
      'recommendations': {
        'learner1': {
          'items': [
            {
              'tutorId': 't1',
              'score': 0.3,
              'name': 'Tutor One',
              'subjects': ['Math'],
              'gradeLevels': ['9'],
              'reasons': ['Reason 1'],
            },
            {
              'tutorId': 't2',
              'score': 0.9,
              'name': 'Tutor Two',
            },
          ],
        },
      },
      'mf_recommendations': {
        'learner1': {
          'items': [
            {'tutorId': 't1', 'score': 0.8},
            {'tutorId': 't3', 'score': 0.95},
          ],
        },
      },
    });
    final service = RecommendationService(store: store);

    final results =
        await service.getHybridTutorRecommendationsForLearner('learner1');

    expect(results.map((r) => r.tutorId).toList(), ['t3', 't2', 't1']);
    final merged = results.firstWhere((r) => r.tutorId == 't1');
    expect(merged.name, 'Tutor One');
    expect(merged.subjects, ['Math']);
    expect(merged.reasons, ['Reason 1']);
  });

  test('getHybridTutorRecommendationsForLearner returns empty on blank id',
      () async {
    final store = InMemoryRecommendationStore({});
    final service = RecommendationService(store: store);
    final results = await service.getHybridTutorRecommendationsForLearner('');
    expect(results, isEmpty);
  });

  test('getContentLearnerRecommendationsForTutor sorts by score', () async {
    final store = InMemoryRecommendationStore({
      'tutor_recommendations': {
        'tutor1': {
          'items': [
            {'learnerId': 'l1', 'score': 0.4},
            {'learnerId': 'l2', 'score': 0.9},
            {'learnerId': 'l3', 'score': 0.6},
          ],
        },
      },
    });
    final service = RecommendationService(store: store);

    final results =
        await service.getContentLearnerRecommendationsForTutor('tutor1');

    expect(results.map((r) => r.learnerId).toList(), ['l2', 'l3', 'l1']);
  });
}
