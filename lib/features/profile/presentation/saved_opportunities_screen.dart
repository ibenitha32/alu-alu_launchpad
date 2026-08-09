import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/opportunity_card.dart';
import '../../../providers/bookmark_providers.dart';
import '../../../providers/opportunity_providers.dart';

class SavedOpportunitiesScreen extends ConsumerWidget {
  const SavedOpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idsAsync = ref.watch(bookmarkedIdsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Saved Opportunities'),
      ),
      body: idsAsync.when(
        data: (ids) {
          if (ids.isEmpty) {
            return const Center(child: Text('No saved opportunities yet'));
          }
          final idList = ids.toList();
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: idList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _SavedOpportunityTile(opportunityId: idList[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SavedOpportunityTile extends ConsumerWidget {
  const _SavedOpportunityTile({required this.opportunityId});
  final String opportunityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunityAsync = ref.watch(opportunityDetailProvider(opportunityId));

    return opportunityAsync.when(
      data: (opportunity) {
        if (opportunity == null) return const SizedBox.shrink();
        return OpportunityCard(
          opportunity: opportunity,
          isBookmarked: true,
          onBookmarkToggle: () =>
              ref.read(bookmarkControllerProvider.notifier).toggle(opportunityId),
          onTap: () => context.push('/opportunity/$opportunityId'),
        );
      },
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, __) => const SizedBox.shrink(),
    );
  }
}
