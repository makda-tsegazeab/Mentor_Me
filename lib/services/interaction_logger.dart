import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight helper to track learner→tutor interaction aggregates.
///
/// Collection: learner_tutor_interactions
/// Doc ID: `${learnerId}_${tutorId}`
///
/// Fields:
/// - learnerId (string)
/// - tutorId (string)
/// - viewCount (int)
/// - messageCount (int)
/// - requestCount (int)
/// - rating (double?; latest rating)
/// - firstInteractionAt (timestamp)
/// - lastInteractionAt (timestamp)
/// - lastEventType ('view' | 'message' | 'request' | 'rating')
class InteractionLogger {
  static final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('learner_tutor_interaction');

  /// Records any learner-initiated action (view / message / request / rating).
  ///
  /// [event] must be one of:
  ///   - 'view'
  ///   - 'message'
  ///   - 'request'
  ///   - 'rating'   (use this when the learner submits/updates a rating)
  ///
  /// If [rating] is provided, it overwrites the stored rating for this pair.
  static Future<void> recordLearnerInteraction({
    required String learnerId,
    required String tutorId,
    required String event,
    double? rating,
  }) async {
    if (learnerId.isEmpty || tutorId.isEmpty) return;

    final docId = '${learnerId}_$tutorId';
    final docRef = _collection.doc(docId);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snapshot = await tx.get(docRef);
        final existing = snapshot.data() ?? <String, dynamic>{};

        int _count(String key) {
          final value = existing[key];
          if (value is num) return value.toInt();
          return 0;
        }

        // Increment only for the relevant event type.
        final viewCount = _count('viewCount') + (event == 'view' ? 1 : 0);
        final messageCount =
            _count('messageCount') + (event == 'message' ? 1 : 0);
        final requestCount =
            _count('requestCount') + (event == 'request' ? 1 : 0);

        final updates = <String, dynamic>{
          'learnerId': learnerId,
          'tutorId': tutorId,
          'viewCount': viewCount,
          'messageCount': messageCount,
          'requestCount': requestCount,
          'lastInteractionAt': FieldValue.serverTimestamp(),
          'lastEventType': event,
        };

        // First interaction timestamp: set once, never changed.
        if (existing['firstInteractionAt'] != null) {
          updates['firstInteractionAt'] = existing['firstInteractionAt'];
        } else {
          updates['firstInteractionAt'] = FieldValue.serverTimestamp();
        }

        // Rating: if a new rating is provided, overwrite; otherwise keep existing.
        final existingRating = existing['rating'];
        if (rating != null) {
          updates['rating'] = rating;
        } else if (existingRating != null) {
          updates['rating'] = existingRating;
        }

        tx.set(docRef, updates, SetOptions(merge: true));
      });
    } catch (e) {
      // We don't want logging failures to break the UX.
      // You can add debug prints here if needed.
      // print('InteractionLogger error: $e');
    }
  }
}
