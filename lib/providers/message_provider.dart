import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/tutoring_request.dart';

class MessageProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================== MESSAGE METHODS ==================
  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String content,
  }) async {
    try {
      final participants = [senderId, receiverId]..sort();

      await _firestore.collection('messages').add({
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'content': content,
        'timestamp': Timestamp.now(),
        'isRead': false,
        'participants': participants,
      });
    } catch (error) {
      throw Exception('Failed to send message: $error');
    }
  }

  Stream<List<Message>> getConversations(String userId) async* {
    try {
      await for (final snapshot in _firestore
          .collection('messages')
          .where('participants', arrayContains: userId)
          .orderBy('timestamp', descending: true)
          .snapshots()) {
        if (snapshot.docs.isEmpty) {
          yield [];
          continue;
        }

        final allMessages = snapshot.docs
            .map((doc) => Message.fromFirestore(doc))
            .where((m) => m.senderId.isNotEmpty && m.receiverId.isNotEmpty)
            .toList();

        // Deduplicate strictly by the *other user id* so each user shows only
        // one conversation entry in the list.
        final conversationMap = <String, Message>{};
        for (final msg in allMessages) {
          final otherUserId =
              msg.senderId == userId ? msg.receiverId : msg.senderId;
          if (!conversationMap.containsKey(otherUserId) ||
              msg.timestamp.isAfter(
                conversationMap[otherUserId]!.timestamp,
              )) {
            conversationMap[otherUserId] = msg;
          }
        }

        yield conversationMap.values.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (error) {
      if (error is FirebaseException &&
          error.code == 'permission-denied') {
        yield [];
        return;
      }
      yield [];
    }
  }

  Stream<List<Message>> getMessages(String currentUserId, String otherUserId) {
    return _firestore
        .collection('messages')
        .where('senderId', whereIn: [currentUserId, otherUserId])
        .where('receiverId', whereIn: [currentUserId, otherUserId])
        .orderBy('timestamp', descending: false)
        .snapshots()
        .handleError((error) => Stream.value([]))
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Message.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> markMessagesAsRead(
    String currentUserId,
    String otherUserId,
  ) async {
    try {
      final query = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      if (query.docs.isNotEmpty) await batch.commit();

      notifyListeners();
    } catch (error) {}
  }

  Stream<int> getUnreadMessageCount(String userId) {
    return _firestore
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) => 0);
  }

  // ================== FIX UTILITIES ==================
  Future<void> addParticipantsToExistingMessages() async {
    try {
      final snapshot = await _firestore.collection('messages').get();
      final batch = _firestore.batch();
      int updatedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final senderId = data['senderId'];
        final receiverId = data['receiverId'];
        if (senderId != null &&
            receiverId != null &&
            data['participants'] == null) {
          final participants = [senderId, receiverId]..sort();
          batch.update(doc.reference, {'participants': participants});
          updatedCount++;
        }
      }

      if (updatedCount > 0) {
        await batch.commit();
      }
    } catch (error) {}
  }

  Future<void> fixMessageNames() async {
    try {
      final snapshot = await _firestore.collection('messages').get();
      final batch = _firestore.batch();
      int updatedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final senderId = data['senderId'];
        if (senderId != null) {
          final userDoc = await _firestore
              .collection('users')
              .doc(senderId)
              .get();
          if (userDoc.exists) {
            final realName = userDoc.data()?['name'];
            if (realName != null && realName != data['senderName']) {
              batch.update(doc.reference, {'senderName': realName});
              updatedCount++;
            }
          }
        }
      }
      if (updatedCount > 0) {
        await batch.commit();
      }
    } catch (error) {}
  }

  // ================== TUTORING REQUEST METHODS ==================
  Future<void> createTutoringRequest(TutoringRequest request) async {
    try {
      // Prevent duplicate pending requests to the same tutor from the same student.
      final existing = await _firestore
          .collection('tutoringRequests')
          .where('studentId', isEqualTo: request.studentId)
          .where('tutorId', isEqualTo: request.tutorId)
          .where('status', isEqualTo: 'pending')
          .get();
      if (existing.docs.isNotEmpty) {
        throw Exception(
            'You already have a pending request with this tutor. Please wait for a response.');
      }

      // Limit to 5 requests total (any status) between the same student/tutor.
      final totalForPair = await _firestore
          .collection('tutoringRequests')
          .where('studentId', isEqualTo: request.studentId)
          .where('tutorId', isEqualTo: request.tutorId)
          .get();
      if (totalForPair.docs.length >= 5) {
        throw Exception(
            'You have reached the limit of 5 requests with this tutor.');
      }

      await _firestore
          .collection('tutoringRequests')
          .doc(request.id)
          .set(request.toMap());
    } catch (error) {
      throw Exception('Failed to create tutoring request: $error');
    }
  }

  Stream<List<TutoringRequest>> getTutoringRequestsForTutor(String tutorId) {
    return _safeRequestStream(
      query: _firestore
          .collection('tutoringRequests')
          .where('tutorId', isEqualTo: tutorId)
          .orderBy('createdAt', descending: true),
    );
  }

  Stream<List<TutoringRequest>> getTutoringRequestsForStudent(
    String studentId,
  ) {
    return _safeRequestStream(
      query: _firestore
          .collection('tutoringRequests')
          .where('studentId', isEqualTo: studentId),
    );
  }

  Stream<List<TutoringRequest>> _safeRequestStream({
    required Query query,
  }) async* {
    try {
      await for (final snapshot in query.snapshots()) {
        final items = <TutoringRequest>[];
        for (final doc in snapshot.docs) {
          final raw = doc.data();
          if (raw is Map<String, dynamic>) {
            items.add(TutoringRequest.fromMap(raw));
          } else if (raw is Map) {
            items.add(TutoringRequest.fromMap(
                Map<String, dynamic>.from(raw as Map)));
          } else {
            debugPrint('Skipped tutoringRequest doc ${doc.id}: invalid data');
          }
        }
        yield items;
      }
    } catch (error) {
      if (error is FirebaseException &&
          error.code == 'permission-denied') {
        yield [];
        return;
      }
      yield [];
    }
  }

  Future<void> updateTutoringRequestStatus({
    required String requestId,
    required String status,
  }) async {
    try {
      await _firestore.collection('tutoringRequests').doc(requestId).update({
        'status': status,
      });
    } catch (error) {
      throw Exception('Failed to update tutoring request: $error');
    }
  }

  // ================== RELATIONSHIP METHODS ==================
  Future<void> createTutoringRelationship({
    required String tutorId,
    required String studentId,
    required String tutorName,
    required String studentName,
    List<String> subjects = const [],
    int sessionsPerWeek = 0,
    int hoursPerSession = 0,
    int? hoursPerWeek,
    List<String>? preferredDays,
    String agreementNotes = '',
    Timestamp? startedAt,
  }) async {
    try {
      final relationshipId = DateTime.now().millisecondsSinceEpoch.toString();
      await _firestore
          .collection('tutoringRelationships')
          .doc(relationshipId)
          .set({
            'id': relationshipId,
            'tutorId': tutorId,
            'studentId': studentId,
            'tutorName': tutorName,
            'studentName': studentName,
            'status': 'active',
            if (startedAt != null) 'startedAt': startedAt,
            'subjects': subjects,
            'sessionsPerWeek': sessionsPerWeek,
            'hoursPerSession': hoursPerSession,
            if (hoursPerWeek != null) 'hoursPerWeek': hoursPerWeek,
            if (preferredDays != null) 'preferredDays': preferredDays,
            'agreementNotes': agreementNotes,
            'createdAt': Timestamp.now(),
          });
    } catch (error) {}
  }

  Future<void> updateRelationshipStatus({
    required String relationshipId,
    required String status,
    Timestamp? endedAt,
  }) async {
    try {
      final payload = <String, dynamic>{
        'status': status,
      };
      if (endedAt != null) {
        payload['endedAt'] = endedAt;
      }
      await _firestore
          .collection('tutoringRelationships')
          .doc(relationshipId)
          .update(payload);
    } catch (error) {
      debugPrint('updateRelationshipStatus error: $error');
      rethrow;
    }
  }

  // ================== BOOKING REQUEST METHODS ==================
  Stream<List<Map<String, dynamic>>> getTutoringRelationships(String userId) async* {
    try {
      await for (final snapshot in _firestore
          .collection('tutoringRelationships')
          .where('tutorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()) {
        yield snapshot.docs.map((doc) => doc.data()).toList();
      }
    } catch (error) {
      debugPrint('getTutoringRelationships error: $error');
      yield [];
    }
  }

  Stream<List<Map<String, dynamic>>> getStudentRelationships(String userId) async* {
    try {
      await for (final snapshot in _firestore
          .collection('tutoringRelationships')
          .where('studentId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()) {
        yield snapshot.docs.map((doc) => doc.data()).toList();
      }
    } catch (error) {
      if (error is FirebaseException &&
          error.code == 'permission-denied') {
        yield [];
        return;
      }
      debugPrint('getStudentRelationships error: $error');
      yield [];
    }
  }
}
