// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/notification_model.dart';

// // Update your notification_provider.dart with better logging
// class NotificationProvider with ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   List<NotificationModel> _notifications = [];
//   List<NotificationModel> get notifications => _notifications;

//   // Create a new notification with better debugging
//   Future<void> createNotification({
//     required String userId,
//     required String title,
//     required String body,
//     required String type,
//     required Map<String, dynamic> data,
//     String? relatedId,
//   }) async {
//     try {
//       final notificationId = _firestore.collection('notifications').doc().id;

//       final notification = NotificationModel(
//         id: notificationId,
//         userId: userId,
//         title: title,
//         body: body,
//         type: type,
//         data: data,
//         timestamp: DateTime.now(),
//         relatedId: relatedId,
//       );

//       print('🔔 Creating notification:');
//       print('   - User ID: $userId');
//       print('   - Title: $title');
//       print('   - Type: $type');
//       print('   - ID: $notificationId');

//       await _firestore
//           .collection('notifications')
//           .doc(notificationId)
//           .set(notification.toMap());

//       print('✅ Notification created successfully for user $userId: $title');

//       // Force refresh the notifications list
//       notifyListeners();
//     } catch (error) {
//       print('❌ FAILED to create notification: $error');
//       print('   - User ID: $userId');
//       print('   - Title: $title');
//       rethrow;
//     }
//   }

//   // Get notifications for a user with better debugging
//   Stream<List<NotificationModel>> getUserNotifications(String userId) {
//     print('📡 Setting up notification stream for user: $userId');

//     return _firestore
//         .collection('notifications')
//         .where('userId', isEqualTo: userId)
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .handleError((error) {
//       print('❌ Notifications stream ERROR: $error');
//       return Stream.value([]);
//     }).map((snapshot) {
//       final notifications = snapshot.docs
//           .map((doc) {
//             try {
//               return NotificationModel.fromMap(doc.data());
//             } catch (e) {
//               print('❌ Error parsing notification doc: $e');
//               return null;
//             }
//           })
//           .where((notif) => notif != null)
//           .cast<NotificationModel>()
//           .toList();

//       print(
//           '📨 Stream update: ${notifications.length} notifications for user $userId');
//       for (var notif in notifications) {
//         print(
//             '   - ${notif.title} (${notif.type}) - ${notif.isRead ? 'READ' : 'UNREAD'}');
//       }

//       return notifications;
//     });
//   }

//   // Get notifications for a user (Stream)
//   // Get notifications for a user (Future)
//   Future<List<NotificationModel>> fetchUserNotifications(String userId) async {
//     try {
//       final snapshot = await _firestore
//           .collection('notifications')
//           .where('userId', isEqualTo: userId)
//           .orderBy('timestamp', descending: true)
//           .get();

//       _notifications = snapshot.docs
//           .map((doc) => NotificationModel.fromMap(doc.data()))
//           .toList();

//       notifyListeners();
//       return _notifications;
//     } catch (error) {
//       print('❌ Failed to fetch notifications: $error');
//       return [];
//     }
//   }

//   // Mark notification as read
//   Future<void> markAsRead(String notificationId) async {
//     try {
//       await _firestore
//           .collection('notifications')
//           .doc(notificationId)
//           .update({'isRead': true});

//       // Update local list - FIXED: Create new instance instead of using copyWith
//       final index = _notifications.indexWhere((n) => n.id == notificationId);
//       if (index != -1) {
//         _notifications[index] = NotificationModel(
//           id: _notifications[index].id,
//           userId: _notifications[index].userId,
//           title: _notifications[index].title,
//           body: _notifications[index].body,
//           type: _notifications[index].type,
//           data: _notifications[index].data,
//           isRead: true, // Mark as read
//           timestamp: _notifications[index].timestamp,
//           relatedId: _notifications[index].relatedId,
//         );
//         notifyListeners();
//       }
//     } catch (error) {
//       print('❌ Failed to mark notification as read: $error');
//     }
//   }

//   // Mark all notifications as read
//   Future<void> markAllAsRead(String userId) async {
//     try {
//       final query = await _firestore
//           .collection('notifications')
//           .where('userId', isEqualTo: userId)
//           .where('isRead', isEqualTo: false)
//           .get();

//       final batch = _firestore.batch();
//       for (final doc in query.docs) {
//         batch.update(doc.reference, {'isRead': true});
//       }

//       if (query.docs.isNotEmpty) {
//         await batch.commit();

//         // Update local list
//         for (int i = 0; i < _notifications.length; i++) {
//           _notifications[i] = NotificationModel(
//             id: _notifications[i].id,
//             userId: _notifications[i].userId,
//             title: _notifications[i].title,
//             body: _notifications[i].body,
//             type: _notifications[i].type,
//             data: _notifications[i].data,
//             isRead: true,
//             timestamp: _notifications[i].timestamp,
//             relatedId: _notifications[i].relatedId,
//           );
//         }
//         notifyListeners();
//       }
//     } catch (error) {
//       print('❌ Failed to mark all notifications as read: $error');
//     }
//   }

//   // Get unread notification count
//   Stream<int> getUnreadCount(String userId) {
//     return _firestore
//         .collection('notifications')
//         .where('userId', isEqualTo: userId)
//         .where('isRead', isEqualTo: false)
//         .snapshots()
//         .map((snapshot) => snapshot.docs.length)
//         .handleError((error) {
//       print('❌ Unread count stream error: $error');
//       return 0;
//     });
//   }

//   // Delete a notification
//   Future<void> deleteNotification(String notificationId) async {
//     try {
//       await _firestore.collection('notifications').doc(notificationId).delete();

//       // Remove from local list
//       _notifications.removeWhere((n) => n.id == notificationId);
//       notifyListeners();
//     } catch (error) {
//       print('❌ Failed to delete notification: $error');
//     }
//   }

//   // Clear all notifications for user
//   Future<void> clearAllNotifications(String userId) async {
//     try {
//       final query = await _firestore
//           .collection('notifications')
//           .where('userId', isEqualTo: userId)
//           .get();

//       final batch = _firestore.batch();
//       for (final doc in query.docs) {
//         batch.delete(doc.reference);
//       }

//       await batch.commit();
//       _notifications.clear();
//       notifyListeners();
//     } catch (error) {
//       print('❌ Failed to clear all notifications: $error');
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  // Create a new notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    required Map<String, dynamic> data,
    String? relatedId,
  }) async {
    try {
      final notificationId = _firestore.collection('notifications').doc().id;

      final notification = NotificationModel(
        id: notificationId,
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
        timestamp: DateTime.now(),
        relatedId: relatedId,
      );

      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .set(notification.toMap());



      notifyListeners();
    } catch (error) {

      rethrow;
    }
  }

  // Get notifications for a user
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {

      return Stream.value([]);
    }).map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Get notifications for a user (Future)
  Future<List<NotificationModel>> fetchUserNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      _notifications = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();

      notifyListeners();
      return _notifications;
    } catch (error) {

      return [];
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // Update local list
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          title: _notifications[index].title,
          body: _notifications[index].body,
          type: _notifications[index].type,
          data: _notifications[index].data,
          isRead: true,
          timestamp: _notifications[index].timestamp,
          relatedId: _notifications[index].relatedId,
        );
        notifyListeners();
      }
    } catch (error) {

    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final query = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      if (query.docs.isNotEmpty) {
        await batch.commit();

        // Update local list
        for (int i = 0; i < _notifications.length; i++) {
          _notifications[i] = NotificationModel(
            id: _notifications[i].id,
            userId: _notifications[i].userId,
            title: _notifications[i].title,
            body: _notifications[i].body,
            type: _notifications[i].type,
            data: _notifications[i].data,
            isRead: true,
            timestamp: _notifications[i].timestamp,
            relatedId: _notifications[i].relatedId,
          );
        }
        notifyListeners();
      }
    } catch (error) {

    }
  }

  // Get unread notification count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {

      return 0;
    });
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();

      // Remove from local list
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (error) {

    }
  }

  // Clear all notifications for user
  Future<void> clearAllNotifications(String userId) async {
    try {
      final query = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      _notifications.clear();
      notifyListeners();
    } catch (error) {

    }
  }
}
