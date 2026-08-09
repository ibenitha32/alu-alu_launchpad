import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/repository_providers.dart';

/// Firestore-backed in-app notifications (no push/FCM setup needed) —
/// written by ApplicationController.updateStatus (status_change) and
/// StartupController.setVerification (verification_result).
final notificationsProvider =
    StreamProvider.autoDispose<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        (ref) {
  final user = ref.watch(currentAppUserProvider).value;
  final firestore = ref.watch(firestoreProvider);
  if (user == null) return const Stream.empty();
  return firestore
      .collection('notifications')
      .doc(user.uid)
      .collection('items')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs);
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final uid = ref.watch(currentAppUserProvider).value?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Notifications'),
      ),
      body: notificationsAsync.when(
        data: (docs) {
          if (docs.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              final read = data['read'] as bool? ?? false;
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: (read || uid == null)
                    ? null
                    : () => ref
                        .read(notificationRepositoryProvider)
                        .markRead(uid: uid, notificationId: doc.id),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: read ? AppColors.surface : AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _iconFor(data['type'] as String? ?? ''),
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data['message'] as String? ?? '',
                          style: AppTextStyles.body,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'status_change':
        return Icons.timeline;
      case 'verification_result':
        return Icons.verified_outlined;
      default:
        return Icons.notifications_none;
    }
  }
}
