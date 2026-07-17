import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/opportunity.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

/// Selected category filter for the discovery screen ("Design", "Engineering", etc).
/// Null = no filter ("all categories").
final categoryFilterProvider = StateProvider<String?>((ref) => null);

/// Free-text search query typed into the search bar.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Raw real-time stream of open opportunities for the selected category.
final openOpportunitiesProvider =
    StreamProvider.autoDispose<List<Opportunity>>((ref) {
  final category = ref.watch(categoryFilterProvider);
  return ref
      .watch(opportunityRepositoryProvider)
      .watchOpenOpportunities(category: category);
});

/// Opportunities filtered client-side by the search box on top of the
/// category-filtered Firestore stream (search-as-you-type on title/skills
/// doesn't need its own round trip for a dataset this size).
final filteredOpportunitiesProvider =
    Provider.autoDispose<AsyncValue<List<Opportunity>>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final opportunities = ref.watch(openOpportunitiesProvider);

  return opportunities.whenData((list) {
    if (query.isEmpty) return list;
    return list.where((o) {
      return o.title.toLowerCase().contains(query) ||
          o.startupName.toLowerCase().contains(query) ||
          o.skillsRequired.any((s) => s.toLowerCase().contains(query));
    }).toList();
  });
});

/// Same list, sorted by skill-match score against the current student's
/// skills — powers the "Recommended" section on the home screen.
final recommendedOpportunitiesProvider =
    Provider.autoDispose<AsyncValue<List<Opportunity>>>((ref) {
  final opportunities = ref.watch(openOpportunitiesProvider);
  final user = ref.watch(currentAppUserProvider).value;
  final skills = user?.skills ?? const <String>[];

  return opportunities.whenData((list) {
    final sorted = [...list]
      ..sort((a, b) => b.matchScore(skills).compareTo(a.matchScore(skills)));
    return sorted.take(5).toList();
  });
});

/// Single-opportunity real-time stream for the detail screen.
final opportunityDetailProvider =
    StreamProvider.autoDispose.family<Opportunity?, String>((ref, id) {
  return ref.watch(opportunityRepositoryProvider).watchOpportunity(id);
});

/// All opportunities posted by a given startup — powers the startup dashboard.
final startupOpportunitiesProvider =
    StreamProvider.autoDispose.family<List<Opportunity>, String>(
        (ref, startupId) {
  return ref
      .watch(opportunityRepositoryProvider)
      .watchStartupOpportunities(startupId);
});

/// Create/update actions with loading state, used by the post-opportunity form.
class OpportunityController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String> create(Opportunity opportunity) async {
    state = const AsyncLoading();
    late String id;
    state = await AsyncValue.guard(() async {
      id = await ref.read(opportunityRepositoryProvider).createOpportunity(
            opportunity,
          );
    });
    return id;
  }

  Future<void> close(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(opportunityRepositoryProvider).closeOpportunity(id),
    );
  }
}

final opportunityControllerProvider =
    AsyncNotifierProvider<OpportunityController, void>(
        OpportunityController.new);
