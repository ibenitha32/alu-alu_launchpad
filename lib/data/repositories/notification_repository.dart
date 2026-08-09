import 'package:cloud_firestore/cloud_firestore.dart';

/// Abstract interface for writing/reading the in-app notification feed at
/// notifications/{uid}/items — see firebase/firestore.rules for the
/// already-scoped security rule this repository writes against.
abstract class NotificationRepository {
  /// Queues a notification for [uid]. Called by other controllers
  /// (application status changes, startup verification results) — never
  /// directly by the recipient.
  Future<void> notify({
    required String uid,
    required String type,
    required String message,
  });

  Future<void> markRead({required String uid, required String notificationId});
}

class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _itemsCol(String uid) => _firestore
      .collection('notifications')
      .doc(uid)
      .collection('items');

  @override
  Future<void> notify({
    required String uid,
    required String type,
    required String message,
  }) async {
    await _itemsCol(uid).add({
      'type': type,
      'message': message,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markRead({
    required String uid,
    required String notificationId,
  }) async {
    await _itemsCol(uid).doc(notificationId).update({'read': true});
  }
}
