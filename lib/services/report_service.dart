import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  static const Duration cooldown = Duration(hours: 24);
  static final CollectionReference _reports =
      FirebaseFirestore.instance.collection('reports');
  static final CollectionReference _limits =
      FirebaseFirestore.instance.collection('report_limits');

  static Future<DateTime?> getLastReportAt(
    String reporterId,
    String reportedId,
  ) async {
    final doc = await _limits.doc('${reporterId}_$reportedId').get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>?;
    final ts = data?['lastReportedAt'] as Timestamp?;
    return ts?.toDate();
  }

  static Future<bool> canReport(String reporterId, String reportedId) async {
    final last = await getLastReportAt(reporterId, reportedId);
    if (last == null) return true;
    return DateTime.now().difference(last) >= cooldown;
  }

  static Future<void> submitReport({
    required String reporterId,
    required String reportedId,
    required String reason,
    required String details,
    required String contextType,
    String? reporterRole,
    String? reportedRole,
    String? relationshipId,
    String? conversationId,
  }) async {
    await _reports.add({
      'reporterId': reporterId,
      'reportedId': reportedId,
      'reporterRole': reporterRole ?? '',
      'reportedRole': reportedRole ?? '',
      'reason': reason,
      'details': details,
      'contextType': contextType,
      'relationshipId': relationshipId ?? '',
      'conversationId': conversationId ?? '',
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _limits.doc('${reporterId}_$reportedId').set(
      {
        'reporterId': reporterId,
        'reportedId': reportedId,
        'lastReportedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
