// lib/services/recommendation_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recommendations.dart';

abstract class RecommendationStore {
  Future<Map<String, dynamic>?> getDocument(String collection, String docId);
}

class FirestoreRecommendationStore implements RecommendationStore {
  final FirebaseFirestore _db;

  FirestoreRecommendationStore(this._db);

  @override
  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String docId,
  ) async {
    final doc = await _db.collection(collection).doc(docId).get();
    if (!doc.exists) return null;
    return doc.data();
  }
}

class RecommendationService {
  final RecommendationStore _store;

  RecommendationService({RecommendationStore? store, FirebaseFirestore? db})
      : _store = store ??
            FirestoreRecommendationStore(db ?? FirebaseFirestore.instance);

  /// ---- LEARNER SIDE ----
  /// Hybrid recommendation: content-based + MF
  Future<List<HybridTutorRec>> getHybridTutorRecommendationsForLearner(
    String learnerId,
  ) async {
    if (learnerId.isEmpty) return [];

    // Load both docs in parallel
    final contentDataFuture =
        _store.getDocument('recommendations', learnerId);
    final mfDataFuture = _store.getDocument('mf_recommendations', learnerId);

    final contentData = await contentDataFuture;
    final mfData = await mfDataFuture;

    final Map<String, HybridTutorRec> map = {};

    // ---- 1) Content-based scores ----
    if (contentData != null) {
      final itemsRaw = contentData['items'] as List<dynamic>? ?? const [];

      for (final raw in itemsRaw) {
        if (raw is! Map<String, dynamic>) continue;
        final contentRec = ContentTutorRec.fromMap(raw);

        final existing = map[contentRec.tutorId];
        if (existing == null) {
          map[contentRec.tutorId] = HybridTutorRec(
            tutorId: contentRec.tutorId,
            contentScore: contentRec.score,
            mfScore: null,
            name: contentRec.name,
            city: contentRec.city,
            subjects: contentRec.subjects,
            gradeLevels: contentRec.gradeLevels,
            minPricePerHour: contentRec.minPricePerHour,
            reasons: contentRec.reasons,
          );
        } else {
          map[contentRec.tutorId] = existing.copyWith(
            contentScore: contentRec.score,
            name: existing.name ?? contentRec.name,
            city: existing.city ?? contentRec.city,
            subjects: existing.subjects.isNotEmpty
                ? existing.subjects
                : contentRec.subjects,
            gradeLevels: existing.gradeLevels.isNotEmpty
                ? existing.gradeLevels
                : contentRec.gradeLevels,
            minPricePerHour:
                existing.minPricePerHour ?? contentRec.minPricePerHour,
            reasons:
                existing.reasons.isNotEmpty ? existing.reasons : contentRec.reasons,
          );
        }
      }
    }

    // ---- 2) MF scores ----
    if (mfData != null) {
      final itemsRaw = mfData['items'] as List<dynamic>? ?? const [];

      for (final raw in itemsRaw) {
        if (raw is! Map<String, dynamic>) continue;
        final mfRec = MFTutorRec.fromMap(raw);

        final existing = map[mfRec.tutorId];
        if (existing == null) {
          map[mfRec.tutorId] = HybridTutorRec(
            tutorId: mfRec.tutorId,
            contentScore: null,
            mfScore: mfRec.score,
          );
        } else {
          map[mfRec.tutorId] = existing.copyWith(
            mfScore: mfRec.score,
          );
        }
      }
    }

    // Nothing at all: return empty
    if (map.isEmpty) return [];

    // ---- 3) Sort by finalScore descending ----
    final list = map.values.toList()
      ..sort((a, b) => b.finalScore.compareTo(a.finalScore));

    return list;
  }

  /// ---- TUTOR SIDE ----
  /// Content-based only: tutor -> learner
  Future<List<TutorSideLearnerRec>> getContentLearnerRecommendationsForTutor(
    String tutorId,
  ) async {
    if (tutorId.isEmpty) return [];

    final data = await _store.getDocument('tutor_recommendations', tutorId);
    if (data == null) return [];

    final itemsRaw = data['items'] as List<dynamic>? ?? const [];

    final List<TutorSideLearnerRec> result = [];
    for (final raw in itemsRaw) {
      if (raw is! Map<String, dynamic>) continue;
      result.add(TutorSideLearnerRec.fromMap(raw));
    }

    // Just to be safe, sort by score desc
    result.sort((a, b) => b.score.compareTo(a.score));

    return result;
  }
}
