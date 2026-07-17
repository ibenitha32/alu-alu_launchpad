import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/startup.dart';
import '../../../providers/opportunity_providers.dart';
import '../../../providers/startup_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupAsync = ref.watch(myStartupProvider);

    return SafeArea(
      child: startupAsync.when(
        data: (startup) {
          if (startup == null) {
            return _NoStartupYet(onRegister: () => context.push('/register-startup'));
          }
          if (!startup.isVerified) {
            return _PendingVerification(startup: startup);
          }
          final opportunities = ref.watch(startupOpportunitiesProvider(startup.id));

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(startup.name, style: AppTextStyles.heading),
                  FilledButton.icon(
                    onPressed: () => context.push('/startup-dashboard/post'),
                    icon: const Icon(Icons.add),
                    label: const Text('Post'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: const [
                  Icon(Icons.verified, color: AppColors.success, size: 16),
                  SizedBox(width: 4),
                  Text('Verified startup', style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: 20),
              Text('Your opportunities', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 12),
              opportunities.when(
                data: (list) => list.isEmpty
                    ? const Text('No opportunities posted yet.', style: AppTextStyles.caption)
                    : Column(
                        children: list
                            .map((o) => Card(
                                  child: ListTile(
                                    title: Text(o.title),
                                    subtitle: Text('${o.applicantCount} applicants · ${o.status.name}'),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => context.push(
                                        '/startup-dashboard/applicants/${o.id}'),
                                  ),
                                ))
                            .toList(),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, __) => Text('Error: $e'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _NoStartupYet extends StatelessWidget {
  const _NoStartupYet({required this.onRegister});
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('Register your startup to start posting', style: AppTextStyles.sectionTitle, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRegister,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Register Startup'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingVerification extends StatelessWidget {
  const _PendingVerification({required this.startup});
  final Startup startup;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_top, size: 48, color: AppColors.warning),
            const SizedBox(height: 16),
            Text('${startup.name} is awaiting verification', style: AppTextStyles.sectionTitle, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              "A platform admin needs to approve your startup before you can post opportunities.",
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
