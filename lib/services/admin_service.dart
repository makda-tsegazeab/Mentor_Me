import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  static final _users = FirebaseFirestore.instance.collection('users');
  static final _verifications =
      FirebaseFirestore.instance.collection('user_verifications');

  static Future<void> updateVerification({
    required String userId,
    required String adminId,
    required bool verified,
    String? note,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final userRef = _users.doc(userId);
    batch.set(userRef, {'verified': verified}, SetOptions(merge: true));

    final auditRef = _verifications.doc();
    batch.set(auditRef, {
      'userId': userId,
      'adminId': adminId,
      'verified': verified,
      'note': note ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  static Stream<List<QueryDocumentSnapshot>> watchUsers() {
    return _users
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  static Stream<List<QueryDocumentSnapshot>> watchVerificationHistory(
      String userId) {
    return _verifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }
}
