import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';
import 'repository_providers.dart';

/// Real-time set of the current user's bookmarked opportunity IDs — powers
/// the bookmark icon state on every OpportunityCard.
final bookmarkedIdsProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final user = ref.watch(currentAppUserProvider).value;
  if (user == null) return Stream.value(const <String>{});
  return ref.watch(bookmarkRepositoryProvider).watchBookmarkedIds(user.uid);
});

final isBookmarkedProvider = Provider.autoDispose.family<bool, String>(
  (ref, opportunityId) {
    final ids = ref.watch(bookmarkedIdsProvider).value ?? const <String>{};
    return ids.contains(opportunityId);
  },
);

class BookmarkController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> toggle(String opportunityId) async {
    final user = await ref.read(currentAppUserProvider.future);
    if (user == null) return;
    final isBookmarked = ref.read(isBookmarkedProvider(opportunityId));
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(bookmarkRepositoryProvider).toggleBookmark(
            uid: user.uid,
            opportunityId: opportunityId,
            isBookmarked: isBookmarked,
          ),
    );
  }
}

final bookmarkControllerProvider =
    AsyncNotifierProvider<BookmarkController, void>(BookmarkController.new);
