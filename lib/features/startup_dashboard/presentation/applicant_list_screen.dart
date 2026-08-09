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
              Expanded(
                child: Text(
                  // Falls back to a UID fragment for applications submitted
                  // before denormalization was added, or the rare case
                  // where the applicant's AppUser doc is missing.
                  application.studentName.isNotEmpty
                      ? application.studentName
                      : 'Applicant ${application.studentUid.substring(0, 6)}',
                  style: AppTextStyles.cardTitle,
                ),
              ),
              StatusPill(status: application.status),
            ],
          ),
          if (application.studentSkills.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: application.studentSkills
                  .map((s) => _SkillTag(label: s))
                  .toList(),
            ),
          ],
          if (application.studentPortfolioLink?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(
              application.studentPortfolioLink!,
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ],
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
                    .updateStatus(application, ApplicationStatus.shortlisted),
              ),
              _ActionChip(
                label: 'Interview',
                onTap: () => ref
                    .read(applicationControllerProvider.notifier)
                    .updateStatus(application, ApplicationStatus.interview),
              ),
              _ActionChip(
                label: 'Accept',
                onTap: () => ref
                    .read(applicationControllerProvider.notifier)
                    .updateStatus(application, ApplicationStatus.accepted),
              ),
              _ActionChip(
                label: 'Reject',
                onTap: () => ref
                    .read(applicationControllerProvider.notifier)
                    .updateStatus(application, ApplicationStatus.rejected),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillTag extends StatelessWidget {
  const _SkillTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.chipBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
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
