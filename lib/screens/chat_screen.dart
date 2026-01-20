import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/message_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/rating_provider.dart';
import '../widgets/rating_dialog.dart';
import '../models/message_model.dart';
import '../utils/security_utils.dart';
import '../widgets/tutoring_request_dialog.dart';
import '../widgets/ui/empty_state.dart';
import '../services/interaction_logger.dart';
import '../widgets/report_sheet.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _userRole; // user role: student/parent/tutor
  String? _receiverRole; // receiver role
  final ScrollController _scrollController = ScrollController();
  final firebase_auth.User? _currentUser =
      firebase_auth.FirebaseAuth.instance.currentUser;

  bool _isValidChat = true;
  bool _hasMarkedAsRead = false;
  Stream<List<Message>>? _messageStream; // ✅ cache the stream here

  @override
  void initState() {
    super.initState();
    _validateChatAccess();

    // ✅ initialize message stream once
    if (_currentUser != null) {
      _messageStream = Provider.of<MessageProvider>(
        context,
        listen: false,
      ).getMessages(_currentUser!.uid, widget.receiverId);
    }
    // Load role regardless; method guards null internally
    _loadUserRole();
    _loadReceiverRole();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      _markMessagesAsRead();
    });
  }

  Future<void> _loadUserRole() async {
    try {
      if (_currentUser == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      if (!mounted) return;
      if (doc.exists) {
        setState(() {
          _userRole = (doc.data()?['role'] ?? '').toString();
        });
      }
    } catch (_) {}
  }

  bool get _isStudentOrParent =>
      _userRole == 'student' || _userRole == 'parent';

  bool get _receiverIsTutor => _receiverRole == 'tutor';

  void _validateChatAccess() {
    if (_currentUser == null ||
        !SecurityUtils.isValidUserId(widget.receiverId) ||
        !SecurityUtils.isValidUserId(_currentUser!.uid)) {
      setState(() => _isValidChat = false);
    }
  }

  Future<void> _loadReceiverRole() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverId)
          .get();
      if (!mounted) return;
      if (doc.exists) {
        setState(() {
          _receiverRole = (doc.data()?['role'] ?? '').toString();
        });
      }
    } catch (_) {}
  }

  void _openRating() async {
    if (_currentUser == null) return;
    final canRate = await _hasTutoringRelationship();
    if (!canRate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('You can only rate tutors you have worked with.')),
        );
      }
      return;
    }
    final ratingProvider = Provider.of<RatingProvider>(context, listen: false);
    final myRating = await ratingProvider
        .getMyRating(widget.receiverId, _currentUser!.uid)
        .first;
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
            tutorId: widget.receiverId,
            raterId: _currentUser!.uid,
            score: score,
            comment: comment,
            raterRole: _userRole,
          );
          if (_currentUser != null && _isStudentOrParent && _receiverIsTutor) {
            InteractionLogger.recordLearnerInteraction(
              learnerId: _currentUser!.uid,
              tutorId: widget.receiverId,
              event: 'rate',
              rating: score.toDouble(),
            );
          }
        },
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_currentUser == null || _hasMarkedAsRead) return;

    _hasMarkedAsRead = true;

    try {
      final messageProvider = Provider.of<MessageProvider>(
        context,
        listen: false,
      );
      await messageProvider.markMessagesAsRead(
        _currentUser!.uid,
        widget.receiverId,
      );
    } catch (error) {}
  }

  Future<String> _getRealUserName(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists && doc.data()?['name'] != null) {
        return doc.data()!['name'];
      }
    } catch (_) {}
    return 'User';
  }

  Future<int?> _getUserAge(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists && doc.data()?['age'] != null) {
        return int.tryParse(doc.data()!['age'].toString());
      }
    } catch (_) {}
    return null;
  }

  Future<void> _handleProfileTap() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverId)
          .get();
      if (!doc.exists) return;
      final data = doc.data() ?? {};

      if (_currentUser != null && _isStudentOrParent && _receiverIsTutor) {
        InteractionLogger.recordLearnerInteraction(
          learnerId: _currentUser!.uid,
          tutorId: widget.receiverId,
          event: 'view',
        );
      }

      if (!mounted) return;
      _showProfileSheet(data);
    } catch (_) {}
  }

  void _showProfileSheet(Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rating = (data['rating'] as num?)?.toDouble() ??
        (data['ratingAvg'] as num?)?.toDouble() ??
        0.0;
    final city = (data['city'] ?? 'Not set').toString();
    final qualification = (data['qualification'] ?? 'Not provided').toString();
    final sex = (data['sex'] ?? 'Not set').toString();
    final hours = data['hoursPerDay']?.toString() ?? '-';
    final days = data['daysPerWeek']?.toString() ?? '-';
    final price = data['minPricePerHour']?.toString();
    final subjects =
        (data['subjects'] as List<dynamic>? ?? []).cast<String>();
    final grades =
        (data['gradeLevels'] as List<dynamic>? ?? []).cast<String>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          color: Colors.black.withOpacity(0.4),
          child: SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101922) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        height: 5,
                        width: 72,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade700
                              : const Color(0xFFDBE0E6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          child: Text(
                            widget.receiverName.isNotEmpty
                                ? widget.receiverName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.receiverName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF111418),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star,
                                      size: 18, color: Colors.amber.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.grey.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                city,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade900
                            : const Color(0xFFF6F7F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _infoTile('Sex', sex, isDark),
                              _infoTile('Hours/Day', hours, isDark),
                              _infoTile('Days/Week', days, isDark),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _infoTile(
                                  'Price/hr',
                                  price != null ? 'ETB $price' : 'Not set',
                                  isDark),
                              _infoTile('Qualification', qualification, isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (subjects.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Subjects Taught',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111418),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: subjects
                            .map(
                              (s) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : const Color(0xFFF0F8FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey.shade200
                                        : const Color(0xFF111418),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (grades.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Grade Levels',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111418),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: grades
                            .map(
                              (g) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : const Color(0xFFF0F8FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  g,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey.shade200
                                        : const Color(0xFF111418),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openReportSheet() {
    if (_currentUser == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportSheet(
        reportedUserId: widget.receiverId,
        reportedName: widget.receiverName,
        contextType: 'chat',
        reporterRole: _userRole,
        reportedRole: _receiverRole,
      ),
    );
  }

  Future<bool> _hasTutoringRelationship() async {
    if (_currentUser == null || !_isStudentOrParent) return false;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tutoringRelationships')
          .where('tutorId', isEqualTo: widget.receiverId)
          .where('studentId', isEqualTo: _currentUser!.uid)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _showChatActions() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF101922) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('View profile'),
                onTap: () {
                  Navigator.pop(context);
                  _handleProfileTap();
                },
              ),
              FutureBuilder<bool>(
                future: _hasTutoringRelationship(),
                builder: (context, snapshot) {
                  final canRate = snapshot.data == true;
                  if (!canRate) return const SizedBox.shrink();
                  return ListTile(
                    leading: const Icon(Icons.star_outline),
                    title: const Text('Rate tutor'),
                    onTap: () {
                      Navigator.pop(context);
                      _openRating();
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_outlined, color: Colors.red),
                title: const Text('Report user'),
                onTap: () {
                  Navigator.pop(context);
                  _openReportSheet();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoTile(String title, String value, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111418),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (!_isValidChat || _currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot send message: Security error')),
        );
      }
      return;
    }

    final message = SecurityUtils.sanitizeMessage(_messageController.text);
    if (message.isEmpty) return;

    final messageProvider = Provider.of<MessageProvider>(
      context,
      listen: false,
    );

    _getRealUserName(_currentUser!.uid).then((realUserName) {
      messageProvider
          .sendMessage(
            senderId: _currentUser!.uid,
            senderName: realUserName,
            receiverId: widget.receiverId,
            receiverName: widget.receiverName,
            content: message,
          )
          .then((_) {
          if (_isStudentOrParent && _receiverIsTutor) {
            InteractionLogger.recordLearnerInteraction(
              learnerId: _currentUser!.uid,
              tutorId: widget.receiverId,
              event: 'message',
            );
          }
            if (mounted) {
              _messageController.clear();
              _scrollToBottom();
            }
          })
          .catchError((error) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Failed to send: $error')));
            }
          });
    });
  }

  Future<void> _sendTutoringRequest() async {
    if (!_isValidChat || _currentUser == null) return;
    if (!_isStudentOrParent || !_receiverIsTutor) return;

    final currentUserName = await _getRealUserName(_currentUser!.uid);
    final tutorDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.receiverId)
        .get();
    final tutorSubjects =
        (tutorDoc.data()?['subjects'] as List<dynamic>? ?? []).cast<String>();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => TutoringRequestDialog(
        fromUserId: _currentUser!.uid,
        fromUserName: currentUserName,
        toUserId: widget.receiverId,
        toUserName: widget.receiverName,
        availableSubjects: tutorSubjects,
        onRequestSent: (request) async {
          final messageProvider = Provider.of<MessageProvider>(
            context,
            listen: false,
          );
          final notificationProvider = Provider.of<NotificationProvider>(
            context,
            listen: false,
          );
          try {
            await messageProvider.createTutoringRequest(request);
            await notificationProvider.createNotification(
              userId: widget.receiverId,
              title: 'New tutoring request',
              body: '$currentUserName wants to start tutoring with you.',
              type: 'tutoring_request',
              data: {'requestId': request.id, 'studentId': request.studentId},
            );
            await messageProvider.sendMessage(
              senderId: _currentUser!.uid,
              senderName: currentUserName,
              receiverId: widget.receiverId,
              receiverName: widget.receiverName,
              content: request.message.isNotEmpty
                  ? 'Tutoring request: ${request.message}'
                  : 'Sent a tutoring request',
            );
            if (mounted) {
              InteractionLogger.recordLearnerInteraction(
                learnerId: _currentUser!.uid,
                tutorId: widget.receiverId,
                event: 'request',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Tutoring request sent to ${widget.receiverName}.',
                  ),
                ),
              );
            }
          } catch (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to send tutoring request: $error'),
                ),
              );
            }
          }
        },
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2B8CEE);
    const bgLight = Color(0xFFF6F7F8);
    const bgDark = Color(0xFF101922);
    final baseTheme = Theme.of(context);
    final isDark = baseTheme.brightness == Brightness.dark;

    if (!_isValidChat) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('Cannot access this chat due to security restrictions'),
        ),
      );
    }

    return Theme(
      data: baseTheme.copyWith(
        scaffoldBackgroundColor: isDark ? bgDark : bgLight,
        textTheme: GoogleFonts.lexendTextTheme(baseTheme.textTheme),
      ),
      child: Scaffold(
        backgroundColor: isDark ? bgDark : bgLight,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? bgDark : Colors.white,
                  border: isDark
                      ? const Border(
                          bottom: BorderSide(color: Color(0xFF374151)),
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: isDark ? Colors.grey.shade300 : Colors.grey[700],
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _handleProfileTap,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade300,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                widget.receiverName.isNotEmpty
                                    ? widget.receiverName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.receiverName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      color: isDark ? Colors.grey.shade300 : Colors.grey[700],
                      onPressed: _showChatActions,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _currentUser == null
                    ? const Center(
                        child: Text('Please log in to view messages.'),
                      )
                    : StreamBuilder<List<Message>>(
                        stream: _messageStream, // ?. use cached stream
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const EmptyState(
                              icon: Icons.forum_outlined,
                              title: 'No messages yet',
                              message: 'Say hello and start the conversation',
                            );
                          }

                          final messages = snapshot.data!;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollToBottom();
                          });

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isMe = message.senderId == _currentUser!.uid;

                              final isTutoringRequest = message.content
                                  .toLowerCase()
                                  .contains('tutoring request');
                              final bubbleColor = isTutoringRequest
                                  ? (isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200)
                                  : isMe
                                      ? primary
                                      : (isDark
                                          ? Colors.grey.shade800
                                          : Colors.white);
                              final textColor = isTutoringRequest
                                  ? (isDark
                                      ? Colors.grey.shade200
                                      : const Color(0xFF111418))
                                  : isMe
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.grey.shade200
                                          : const Color(0xFF111418));
                              final align =
                                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: isMe
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  children: [
                                    if (!isMe)
                                      Container(
                                        height: 32,
                                        width: 32,
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isDark
                                              ? Colors.grey.shade800
                                              : Colors.grey.shade300,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          message.senderName.isNotEmpty
                                              ? message.senderName[0]
                                                  .toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: align,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                isMe
                                                    ? 'You'
                                                    : message.senderName,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? Colors.grey.shade400
                                                      : Colors.grey.shade500,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _formatTime(message.timestamp),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? Colors.grey.shade500
                                                      : Colors.grey.shade400,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                constraints:
                                                    const BoxConstraints(
                                                  maxWidth: 360,
                                                ),
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        16, 12, 16, 12),
                                                decoration: BoxDecoration(
                                                  color: bubbleColor,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft:
                                                        const Radius.circular(
                                                            16),
                                                    topRight:
                                                        const Radius.circular(
                                                            16),
                                                    bottomLeft: isMe
                                                        ? const Radius.circular(
                                                            16)
                                                        : Radius.zero,
                                                    bottomRight: isMe
                                                        ? Radius.zero
                                                        : const Radius.circular(
                                                            16),
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.05),
                                                      blurRadius: 6,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  message.content,
                                                  style: TextStyle(
                                                    color: textColor,
                                                    fontSize: 15,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                              if (isMe) ...[
                                                const SizedBox(width: 6),
                                                Icon(
                                                  message.isRead
                                                      ? Icons.done_all
                                                      : Icons.done,
                                                  size: 18,
                                                  color: message.isRead
                                                      ? primary
                                                      : (isDark
                                                          ? Colors
                                                              .grey.shade500
                                                          : Colors
                                                              .grey.shade500),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? bgDark : Colors.white,
                  border: Border(
                    top: BorderSide(
                        color: isDark
                            ? const Color(0xFF374151)
                            : Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    if (_isStudentOrParent && _receiverIsTutor)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _sendTutoringRequest,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.school),
                          label: const Text(
                            'Request Tutoring',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: isDark ? bgDark : Colors.white,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade500,
                      onPressed: () {},
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          filled: true,
                          fillColor:
                              isDark ? Colors.grey.shade800 : Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: primary,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
