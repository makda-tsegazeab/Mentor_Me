import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String receiverName;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final List<String> participants;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.receiverName,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    required this.participants,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Safe timestamp handling
    DateTime timestamp;
    try {
      if (data['timestamp'] != null) {
        timestamp = (data['timestamp'] as Timestamp).toDate();
      } else {
        timestamp = DateTime.now();
      }
    } catch (e) {
      timestamp = DateTime.now();
    }

    // Safe participants handling
    List<String> participants;
    try {
      participants = List<String>.from(data['participants'] ?? []);
    } catch (e) {
      participants = [];
    }

    return Message(
      id: doc.id,
      senderId: data['senderId']?.toString() ?? '',
      receiverId: data['receiverId']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? 'Unknown',
      receiverName: data['receiverName']?.toString() ?? 'Unknown',
      content: data['content']?.toString() ?? '',
      timestamp: timestamp,
      isRead: data['isRead'] ?? false,
      participants: participants,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'receiverName': receiverName,
      'content': content,
      'timestamp': timestamp,
      'isRead': isRead,
      'participants': participants,
    };
  }
}
