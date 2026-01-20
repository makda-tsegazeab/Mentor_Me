import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  static final _users = FirebaseFirestore.instance.collection('users');
  static final _verifications =
      FirebaseFirestore.instance.collection('user_verifications');
  static final _suspensions =
      FirebaseFirestore.instance.collection('user_suspensions');

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

  static Future<void> updateSuspension({
    required String userId,
    required String adminId,
    required bool suspended,
    String? note,
    String? code,
    int? score,
    String? level,
    Map<String, int>? rubric,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final userRef = _users.doc(userId);
    final userUpdate = <String, dynamic>{
      'suspended': suspended,
    };
    if (suspended) {
      userUpdate['suspendedAt'] = FieldValue.serverTimestamp();
      if (code != null) userUpdate['suspensionCode'] = code;
      if (score != null) userUpdate['suspensionScore'] = score;
      if (level != null) userUpdate['suspensionLevel'] = level;
      if (note != null && note.trim().isNotEmpty) {
        userUpdate['suspensionNote'] = note.trim();
      }
      if (rubric != null) userUpdate['suspensionRubric'] = rubric;
    } else {
      userUpdate['suspensionClearedAt'] = FieldValue.serverTimestamp();
    }
    batch.set(userRef, userUpdate, SetOptions(merge: true));

    final auditRef = _suspensions.doc();
    batch.set(auditRef, {
      'userId': userId,
      'adminId': adminId,
      'suspended': suspended,
      'note': note ?? '',
      'code': code,
      'score': score,
      'level': level,
      'rubric': rubric,
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

  static Stream<List<QueryDocumentSnapshot>> watchSuspensionHistory(
      String userId) {
    return _suspensions
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }
}
