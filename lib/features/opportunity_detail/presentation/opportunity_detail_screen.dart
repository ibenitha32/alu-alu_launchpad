import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/opportunity.dart';
import '../../../providers/application_providers.dart';
import '../../../providers/opportunity_providers.dart';

class OpportunityDetailScreen extends ConsumerWidget {
  const OpportunityDetailScreen({super.key, required this.opportunityId});

  final String opportunityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunityAsync =
        ref.watch(opportunityDetailProvider(opportunityId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Opportunity Details'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: opportunityAsync.when(
        data: (opportunity) {
          if (opportunity == null) {
            return const Center(child: Text('This opportunity no longer exists.'));
          }
          final hasApplied = ref.watch(hasAppliedProvider(opportunityId));
          final applyState = ref.watch(applicationControllerProvider);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.auto_awesome,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(opportunity.title, style: AppTextStyles.heading),
                        Text(opportunity.startupName,
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: opportunity.skillsRequired
                      .map((s) => Chip(label: Text(s)))
                      .toList(),
                ),
                const SizedBox(height: 20),
                _InfoRow(icon: Icons.schedule, text: _commitmentLabel(opportunity)),
                _InfoRow(icon: Icons.location_on_outlined, text: _locationLabel(opportunity)),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  text: 'Posted ${DateTime.now().difference(opportunity.postedAt).inDays}d ago',
                ),
                const SizedBox(height: 20),
                Text('About', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 8),
                Text(opportunity.description, style: AppTextStyles.body),
                const SizedBox(height: 20),
                Text('Skills required', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: opportunity.skillsRequired
                      .map((s) => Chip(label: Text(s)))
                      .toList(),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: hasApplied ? 'Applied' : 'Apply Now',
                  isLoading: applyState.isLoading,
                  onPressed: hasApplied
                      ? null
                      : () => _showApplySheet(context, ref, opportunity.id,
                          opportunity.startupId),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error loading opportunity: $e')),
      ),
    );
  }

  void _showApplySheet(BuildContext context, WidgetRef ref,
      String opportunityId, String startupId) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add a note (optional)', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Why are you a good fit for this role?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Submit Application',
              onPressed: () async {
                await ref.read(applicationControllerProvider.notifier).apply(
                      opportunityId: opportunityId,
                      startupId: startupId,
                      coverNote: controller.text.trim(),
                    );
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(text, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

String _commitmentLabel(Opportunity o) {
  switch (o.commitment) {
    case Commitment.fullTime:
      return 'Full-time';
    case Commitment.projectBased:
      return 'Project-based';
    case Commitment.partTime:
      return 'Part-time (8-10 hrs/week)';
  }
}

String _locationLabel(Opportunity o) {
  switch (o.location) {
    case WorkLocation.onCampus:
      return 'On-campus';
    case WorkLocation.hybrid:
      return 'Hybrid';
    case WorkLocation.remote:
      return 'Remote';
  }
}
