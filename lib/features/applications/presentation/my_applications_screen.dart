import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/models/job_application.dart';
import '../../../providers/application_providers.dart';
import '../../../providers/opportunity_providers.dart';

class MyApplicationsScreen extends ConsumerStatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  ConsumerState<MyApplicationsScreen> createState() =>
      _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends ConsumerState<MyApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final applicationsAsync = ref.watch(myApplicationsProvider);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('My Applications', style: AppTextStyles.heading),
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Applied'),
              Tab(text: 'Interview'),
              Tab(text: 'Accepted'),
              Tab(text: 'All'),
            ],
          ),
          Expanded(
            child: applicationsAsync.when(
              data: (apps) => TabBarView(
                controller: _tabController,
                children: [
                  _AppList(apps: apps
                      .where((a) => a.status == ApplicationStatus.applied)
                      .toList()),
                  _AppList(apps: apps
                      .where((a) => a.status == ApplicationStatus.interview)
                      .toList()),
                  _AppList(apps: apps
                      .where((a) => a.status == ApplicationStatus.accepted)
                      .toList()),
                  _AppList(apps: apps),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppList extends StatelessWidget {
  const _AppList({required this.apps});
  final List<JobApplication> apps;

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return const Center(child: Text('Nothing here yet'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: apps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _ApplicationTile(application: apps[i]),
    );
  }
}

class _ApplicationTile extends ConsumerWidget {
  const _ApplicationTile({required this.application});
  final JobApplication application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunity =
        ref.watch(opportunityDetailProvider(application.opportunityId)).value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(opportunity?.title ?? 'Opportunity',
                    style: AppTextStyles.cardTitle),
                Text(
                  'Applied ${DateTime.now().difference(application.appliedAt).inDays}d ago',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          StatusPill(status: application.status),
        ],
      ),
    );
  }
}
