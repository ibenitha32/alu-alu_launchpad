import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/models/job_application.dart';
import '../../../providers/application_providers.dart';

class ApplicantListScreen extends ConsumerWidget {
  const ApplicantListScreen({super.key, required this.opportunityId});

  final String opportunityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicantsAsync =
        ref.watch(opportunityApplicantsProvider(opportunityId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Applicants'),
      ),
      body: applicantsAsync.when(
        data: (applicants) {
          if (applicants.isEmpty) {
            return const Center(child: Text('No applicants yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: applicants.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _ApplicantTile(application: applicants[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ApplicantTile extends ConsumerWidget {
  const _ApplicantTile({required this.application});
  final JobApplication application;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Applicant ${application.studentUid.substring(0, 6)}',
                  style: AppTextStyles.cardTitle),
              StatusPill(status: application.status),
            ],
          ),
          if (application.coverNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(application.coverNote, style: AppTextStyles.body),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _ActionChip(
                label: 'Shortlist',
                onTap: () => ref
                    .read(applicationControllerProvider.notifier)
                    .updateStatus(application.id, ApplicationStatus.shortlisted),
              ),
              _ActionChip(
                label: 'Interview',
                onTap: () => ref
                    .read(applicationControllerProvider.notifier)
                    .updateStatus(application.id, ApplicationStatus.interview),
              ),
              _ActionChip(
                label: 'Accept',
                onTap: () => ref
                    .read(applicationControllerProvider.notifier)
                    .updateStatus(application.id, ApplicationStatus.accepted),
              ),
              _ActionChip(
                label: 'Reject',
                onTap: () => ref
                    .read(applicationControllerProvider.notifier)
                    .updateStatus(application.id, ApplicationStatus.rejected),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.chipBackground,
    );
  }
}
