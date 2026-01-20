import 'package:flutter_test/flutter_test.dart';
import 'package:hey_tutor/models/notification_model.dart';

void main() {
  test('NotificationModel toMap/fromMap round-trip', () {
    final timestamp = DateTime(2024, 4, 5, 6, 7);
    final notification = NotificationModel(
      id: 'n1',
      userId: 'u1',
      title: 'New Message',
      body: 'You have a new message',
      type: 'message',
      data: {'threadId': 't1'},
      isRead: true,
      timestamp: timestamp,
      relatedId: 'rel-1',
    );

    final map = notification.toMap();
    final parsed = NotificationModel.fromMap(map);

    expect(parsed.id, notification.id);
    expect(parsed.userId, notification.userId);
    expect(parsed.title, notification.title);
    expect(parsed.body, notification.body);
    expect(parsed.type, notification.type);
    expect(parsed.data, notification.data);
    expect(parsed.isRead, notification.isRead);
    expect(parsed.timestamp, notification.timestamp);
    expect(parsed.relatedId, notification.relatedId);
  });

  test('NotificationModel copyWith overrides provided fields', () {
    final base = NotificationModel(
      id: 'n2',
      userId: 'u2',
      title: 'Old',
      body: 'Old body',
      type: 'info',
      data: const {'a': 1},
      timestamp: DateTime(2024, 1, 1),
    );

    final updated = base.copyWith(
      title: 'New',
      isRead: true,
      data: const {'b': 2},
    );

    expect(updated.id, base.id);
    expect(updated.title, 'New');
    expect(updated.isRead, isTrue);
    expect(updated.data, const {'b': 2});
  });
}
