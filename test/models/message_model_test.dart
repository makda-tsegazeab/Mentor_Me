import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hey_tutor/models/message_model.dart';

void main() {
  test('Message.fromMap maps fields and timestamp', () {
    final sentAt = DateTime(2024, 2, 3, 4, 5);

    final message = Message.fromMap('m1', {
      'senderId': 's1',
      'receiverId': 'r1',
      'senderName': 'Sender',
      'receiverName': 'Receiver',
      'content': 'Hello',
      'timestamp': Timestamp.fromDate(sentAt),
      'isRead': true,
      'participants': ['s1', 'r1'],
    });

    expect(message.id, 'm1');
    expect(message.senderId, 's1');
    expect(message.receiverId, 'r1');
    expect(message.senderName, 'Sender');
    expect(message.receiverName, 'Receiver');
    expect(message.content, 'Hello');
    expect(message.timestamp, sentAt);
    expect(message.isRead, isTrue);
    expect(message.participants, ['s1', 'r1']);
  });

  test('Message.fromMap handles missing/invalid fields safely', () {
    final before = DateTime.now();

    final message = Message.fromMap('m2', {
      'senderId': null,
      'participants': 'bad',
      'timestamp': 'bad',
    });

    expect(message.senderId, '');
    expect(message.receiverId, '');
    expect(message.senderName, 'Unknown');
    expect(message.receiverName, 'Unknown');
    expect(message.content, '');
    expect(
      message.timestamp.isAfter(before.subtract(const Duration(seconds: 1))),
      isTrue,
    );
    expect(message.participants, isEmpty);
    expect(message.isRead, isFalse);
  });
}
