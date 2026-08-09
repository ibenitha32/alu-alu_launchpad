import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/opportunity_card.dart';
import '../../../data/models/opportunity.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/bookmark_providers.dart';
import '../../../providers/opportunity_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _categoryIcons = {
    OpportunityCategory.design: Icons.brush_outlined,
    OpportunityCategory.engineering: Icons.code,
    OpportunityCategory.marketing: Icons.campaign_outlined,
    OpportunityCategory.operations: Icons.business_center_outlined,
    OpportunityCategory.research: Icons.science_outlined,
    OpportunityCategory.content: Icons.article_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider).value;
    final recommended = ref.watch(recommendedOpportunitiesProvider);
    final filtered = ref.watch(filteredOpportunitiesProvider);
    final bookmarkedIds = ref.watch(bookmarkedIdsProvider).value ?? const <String>{};

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello, ${user?.name.split(' ').first ?? ''} 👋',
                      style: AppTextStyles.heading),
                  Text('Find meaningful ways to contribute.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.push('/notifications'),
                    icon: const Icon(Icons.notifications_none),
                  ),
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (v) =>
                ref.read(searchQueryProvider.notifier).state = v,
            decoration: InputDecoration(
              hintText: 'Search opportunities...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recommended', style: AppTextStyles.sectionTitle),
              TextButton(onPressed: () {}, child: const Text('See all')),
            ],
          ),
          const SizedBox(height: 8),
          recommended.when(
            data: (list) => list.isEmpty
                ? const _EmptyHint(text: 'No recommendations yet — add skills in your profile')
                : SizedBox(
                    height: 190,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => SizedBox(
                        width: 280,
                        child: OpportunityCard(
                          opportunity: list[i],
                          featured: true,
                          isBookmarked: bookmarkedIds.contains(list[i].id),
                          onBookmarkToggle: () => ref
                              .read(bookmarkControllerProvider.notifier)
                              .toggle(list[i].id),
                          onTap: () =>
                              context.push('/opportunity/${list[i].id}'),
                        ),
                      ),
                    ),
                  ),
            loading: () => const _LoadingHint(),
            error: (e, __) => _ErrorHint(message: e.toString()),
          ),
          const SizedBox(height: 24),
          Text('Browse by category', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _categoryIcons.entries.map((entry) {
              final selected = ref.watch(categoryFilterProvider) == entry.key;
              return _CategoryIcon(
                label: entry.key.label,
                icon: entry.value,
                selected: selected,
                onTap: () => ref.read(categoryFilterProvider.notifier).state =
                    selected ? null : entry.key,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Recent opportunities', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          filtered.when(
            data: (list) => list.isEmpty
                ? const _EmptyHint(text: 'No opportunities match yet')
                : Column(
                    children: list
                        .map((o) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: OpportunityCard(
                                opportunity: o,
                                isBookmarked: bookmarkedIds.contains(o.id),
                                onBookmarkToggle: () => ref
                                    .read(bookmarkControllerProvider.notifier)
                                    .toggle(o.id),
                                onTap: () =>
                                    context.push('/opportunity/${o.id}'),
                              ),
                            ))
                        .toList(),
                  ),
            loading: () => const _LoadingHint(),
            error: (e, __) => _ErrorHint(message: e.toString()),
          ),
        ],
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.chipBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon,
                color: selected ? AppColors.primary : AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(text,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      );
}

class _LoadingHint extends StatelessWidget {
  const _LoadingHint();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _ErrorHint extends StatelessWidget {
  const _ErrorHint({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('Something went wrong: $message',
            style: AppTextStyles.caption.copyWith(color: Colors.red)),
      );
}
