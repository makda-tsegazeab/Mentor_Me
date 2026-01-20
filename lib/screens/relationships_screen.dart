import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/tutoring_request.dart';
import '../providers/message_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/rating_provider.dart';
import '../widgets/ui/empty_state.dart' as ui;
import '../widgets/rating_dialog.dart';
import '../widgets/report_sheet.dart';

class RelationshipsScreen extends StatefulWidget {
  final int initialTab;

  const RelationshipsScreen({super.key, this.initialTab = 0});

  @override
  State<RelationshipsScreen> createState() => _RelationshipsScreenState();
}

class _RelationshipsScreenState extends State<RelationshipsScreen> {
  String? _userId;
  String? _userRole;
  bool _isLoading = true;
  late int _selectedTab; // 0 = Tutoring Requests, 1 = Students/Relationships

  TextStyle _lexend({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
  }) {
    return GoogleFonts.lexend(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _loadCurrentUserRole();
  }

  Future<void> _loadCurrentUserRole() async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    String role = 'student';
    if (snapshot.exists && snapshot.data()?['role'] != null) {
      role = snapshot.data()!['role'].toString();
    } else {
      final tutorDoc = await FirebaseFirestore.instance
          .collection('tutors')
          .doc(currentUser.uid)
          .get();
      if (tutorDoc.exists) role = 'tutor';
    }

    if (mounted) {
      setState(() {
        _userRole = role;
        _userId = currentUser.uid;
        _isLoading = false;
      });
    }
  }

  bool get _isTutor => _userRole == 'tutor';
  bool get _isLearner => _userRole == 'student' || _userRole == 'parent';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg =
        isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8);
    final primary = const Color(0xFF2B8CEE);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to see your tutoring requests.'),
        ),
      );
    }

    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);
    final requestsStream = _isTutor
        ? messageProvider.getTutoringRequestsForTutor(_userId!)
        : messageProvider.getTutoringRequestsForStudent(_userId!);
    final relationshipsStream = _isTutor
        ? messageProvider.getTutoringRelationships(_userId!)
        : messageProvider.getStudentRelationships(_userId!);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: StreamBuilder<List<TutoringRequest>>(
          stream: requestsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !(snapshot.hasData && (snapshot.data?.isNotEmpty ?? false))) {
              return const Center(child: CircularProgressIndicator());
            }

            final requests = snapshot.data ?? [];
            final sortedRequests = List<TutoringRequest>.from(requests)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: relationshipsStream,
              builder: (context, relSnapshot) {
                if (relSnapshot.connectionState == ConnectionState.waiting &&
                    !(relSnapshot.hasData &&
                        (relSnapshot.data?.isNotEmpty ?? false))) {
                  return const Center(child: CircularProgressIndicator());
                }
                final relationships = relSnapshot.data ?? [];

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          const SizedBox(width: 48),
                          Expanded(
                            child: Text(
                              'Relationships',
                              textAlign: TextAlign.center,
                              style: _lexend(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111418),
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => setState(() => _selectedTab = 0),
                                  child: Text(
                                    'Tutoring Requests',
                                    style: _lexend(
                                      fontSize: 14,
                                      fontWeight: _selectedTab == 0
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: _selectedTab == 0
                                          ? (isDark ? Colors.white : primary)
                                          : (isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600),
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: _selectedTab == 0
                                      ? (isDark ? Colors.grey.shade700 : Colors.white)
                                      : Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextButton(
                                onPressed: () => setState(() => _selectedTab = 1),
                                  child: Text(
                                    _isTutor ? 'Students' : 'Tutors',
                                    style: _lexend(
                                      fontSize: 14,
                                      fontWeight: _selectedTab == 1
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: _selectedTab == 1
                                          ? (isDark ? Colors.white : primary)
                                          : (isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600),
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: _selectedTab == 1
                                      ? (isDark ? Colors.grey.shade700 : Colors.white)
                                      : Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: _selectedTab == 0
                            ? _buildRequestsSection(sortedRequests)
                            : _buildRelationshipsSection(relationships),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRequestsSection(List<TutoringRequest> requests) {
    final primary = const Color(0xFF2B8CEE);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (requests.isEmpty) {
      final bg = isDark ? Colors.blueGrey.shade900 : Colors.blue.shade50;
      final fg = isDark ? Colors.blue.shade200 : primary;
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.class_, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your tutoring requests will appear here.',
                  style: _lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF111418),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: requests.map(_buildRequestCard).toList(),
    );
  }

  Widget _buildRelationshipsSection(List<Map<String, dynamic>> relationships) {
    if (relationships.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final bg =
          isDark ? Colors.blueGrey.shade900 : Colors.blue.shade50;
      final fg = isDark ? Colors.blue.shade200 : const Color(0xFF2B8CEE);
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.handshake, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your tutoring relationships will appear here.',
                  style: _lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF111418),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: relationships.map(_buildRelationshipCard).toList(),
    );
  }

  Widget _buildRequestCard(TutoringRequest request) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primary = Color(0xFF2B8CEE);
    final statusColor = _statusColor(request.status);
    final displayStatus = request.status[0].toUpperCase() +
        request.status.substring(1).replaceAll('_', ' ');
    final days = request.preferredDays;
    final hours = request.hoursPerWeek;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isTutor ? request.studentName : request.tutorName,
                    style: _lexend(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    displayStatus,
                    style: _lexend(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (request.message.isNotEmpty)
              Text(
                '"${request.message}"',
                style: _lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ).copyWith(fontStyle: FontStyle.italic),
              ),
    if (request.subjects.isNotEmpty) ...[
      const SizedBox(height: 8),
      Text(
        'Subjects: ${request.subjects.join(', ')}',
        style: _lexend(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
      ),
    ],
    if (days.isNotEmpty || hours > 0) ...[
      const SizedBox(height: 6),
      Text(
        hours > 0 ? 'Hours per week: $hours' : '',
        style: _lexend(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      if (days.isNotEmpty)
        Text(
          'Preferred days: ${days.join(', ')}',
          style: _lexend(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
    ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.yMMMd()
                      .add_jm()
                      .format(request.createdAt.toDate()),
                  style: _lexend(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                if (_isTutor && request.status == 'pending')
                  Row(
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red.shade100,
                          foregroundColor: Colors.red.shade600,
                          minimumSize: const Size(0, 36),
                        ),
                        onPressed: () => _respondToRequest(
                          request,
                          approve: false,
                        ),
                        child: Text(
                          'Decline',
                          style: _lexend(
                              fontWeight: FontWeight.w700,
                              color: Colors.red.shade600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade500,
                          minimumSize: const Size(0, 36),
                        ),
                        onPressed: () => _respondToRequest(
                          request,
                          approve: true,
                        ),
                        child: Text(
                          'Approve',
                          style: _lexend(
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                if (!_isTutor)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      displayStatus,
                      style: _lexend(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openReportForRelationship(Map<String, dynamic> data) {
    final partnerId = _isTutor ? data['studentId'] : data['tutorId'];
    if (partnerId == null || partnerId.toString().isEmpty) return;
    final partnerName = _isTutor ? data['studentName'] : data['tutorName'];
    final reportedRole = _isTutor ? 'student' : 'tutor';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportSheet(
        reportedUserId: partnerId.toString(),
        reportedName: (partnerName ?? 'User').toString(),
        contextType: 'relationship',
        reporterRole: _userRole,
        reportedRole: reportedRole,
        relationshipId: data['id']?.toString(),
      ),
    );
  }

  Future<void> _openRatingForRelationship(Map<String, dynamic> data) async {
    if (!_isLearner || _userId == null) return;
    final partnerId = data['tutorId']?.toString();
    if (partnerId == null || partnerId.isEmpty) return;
    final ratingProvider = Provider.of<RatingProvider>(context, listen: false);
    final myRating =
        await ratingProvider.getMyRating(partnerId, _userId!).first;
    final initialScore = (myRating?['score'] ?? 0) as int;
    final initialComment = myRating?['comment'] as String?;
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => RatingDialog(
        initialScore: initialScore,
        initialComment: initialComment,
        onSubmit: (score, comment) async {
          await ratingProvider.submitRating(
            tutorId: partnerId,
            raterId: _userId!,
            score: score,
            comment: comment,
            raterRole: _userRole,
            relationshipId: data['id']?.toString(),
          );
        },
      ),
    );
  }

  Widget _buildRelationshipCard(Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final partnerName = _isTutor ? data['studentName'] : data['tutorName'];
    final partnerRole = _isTutor ? 'Student' : 'Tutor';
    final startedAt = data['startedAt'] as Timestamp?;
    final endedAt = data['endedAt'] as Timestamp?;
    final relationshipId = data['id']?.toString();
    final startedLabel = startedAt != null
        ? DateFormat.yMMMd().format(startedAt.toDate())
        : 'Awaiting start';
    final status = (data['status'] ?? 'active').toString();
    final statusLabel =
        '${status[0].toUpperCase()}${status.substring(1)}';
    final endedLabel =
        endedAt != null ? DateFormat.yMMMd().format(endedAt.toDate()) : null;
    final canRate = _isLearner && relationshipId != null;
    final canEnd = relationshipId != null && status != 'ended';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    partnerName ?? 'Learner',
                    style: _lexend(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'report') {
                      _openReportForRelationship(data);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'report',
                      child: Text('Report user'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              partnerRole,
              style: _lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              'Start: $startedLabel',
              style: _lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'Status: $statusLabel',
              style: _lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface),
            ),
            if (endedLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                'Ended: $endedLabel',
                style: _lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface),
              ),
            ],
            const SizedBox(height: 12),
            if (canRate || canEnd)
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canRate)
                      TextButton(
                        onPressed: () => _openRatingForRelationship(data),
                        child: Text(
                          'Rate Tutor',
                          style: _lexend(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    if (canRate && canEnd) const SizedBox(width: 8),
                    if (canEnd)
                      TextButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('End tutoring relationship?'),
                              content: const Text(
                                  'Are you sure you want to stop this tutoring relationship?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Yes, end'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await Provider.of<MessageProvider>(context,
                                      listen: false)
                                  .updateRelationshipStatus(
                                relationshipId: relationshipId,
                                status: 'ended',
                                endedAt: Timestamp.now(),
                              );
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Failed to end relationship: $e'),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: Text(
                          'End Relationship',
                          style: _lexend(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _respondToRequest(TutoringRequest request,
      {required bool approve}) async {
    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    try {
      await messageProvider.updateTutoringRequestStatus(
        requestId: request.id,
        status: approve ? 'approved' : 'declined',
      );
      if (approve) {
        await messageProvider.createTutoringRelationship(
          tutorId: request.tutorId,
          studentId: request.studentId,
          tutorName: request.tutorName,
          studentName: request.studentName,
          subjects: request.subjects,
          hoursPerWeek: request.hoursPerWeek,
          preferredDays: request.preferredDays,
          agreementNotes: request.message,
          startedAt: Timestamp.now(),
        );
      }

      await notificationProvider.createNotification(
        userId: request.studentId,
        title:
            approve ? 'Tutoring request approved' : 'Tutoring request declined',
        body: approve
            ? '${request.tutorName} accepted your tutoring request.'
            : '${request.tutorName} declined your tutoring request.',
        type:
            approve ? 'tutoring_request_approved' : 'tutoring_request_declined',
        data: {
          'requestId': request.id,
          'tutorId': request.tutorId,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve
                ? 'Tutoring relationship activated.'
                : 'Request declined.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update request: $error')),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green.shade700;
      case 'declined':
        return Colors.red.shade700;
      default:
        return Colors.orange.shade700;
    }
  }
}
