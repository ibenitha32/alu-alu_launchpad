import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/startup.dart';
import '../../../providers/startup_providers.dart';

class AdminVerificationQueueScreen extends ConsumerWidget {
  const AdminVerificationQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingStartupsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Verification Queue'),
      ),
      body: pendingAsync.when(
        data: (startups) {
          if (startups.isEmpty) {
            return const Center(child: Text('No startups awaiting review'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: startups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _StartupReviewCard(startup: startups[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StartupReviewCard extends ConsumerWidget {
  const _StartupReviewCard({required this.startup});
  final Startup startup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(startup.name, style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text(startup.sector, style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Text(startup.description, style: AppTextStyles.body),
          const SizedBox(height: 8),
          Text('Contact: ${startup.contactEmail}', style: AppTextStyles.caption),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref
                      .read(startupControllerProvider.notifier)
                      .setVerification(
                          startupId: startup.id,
                          status: VerificationStatus.rejected),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () => ref
                      .read(startupControllerProvider.notifier)
                      .setVerification(
                          startupId: startup.id,
                          status: VerificationStatus.verified),
                  child: const Text('Verify'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
