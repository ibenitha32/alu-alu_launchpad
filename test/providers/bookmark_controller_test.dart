import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alu_launchpad/data/models/app_user.dart';
import 'package:alu_launchpad/providers/auth_providers.dart';
import 'package:alu_launchpad/providers/bookmark_providers.dart';
import 'package:alu_launchpad/providers/repository_providers.dart';

import '../fakes/fake_repositories.dart';

/// Covers the bookmark repository/controller added for Problem 4 of the
/// resubmission, using the same fake-repository pattern as the other
/// controller tests.
void main() {
  final testStudent = AppUser(
    uid: 'student-1',
    name: 'Amina Hassan',
    email: 'amina@alustudent.com',
    role: UserRole.student,
    createdAt: DateTime(2026, 1, 1),
  );

  test('toggle() bookmarks an opportunity, then un-bookmarks it on a second call',
      () async {
    final fakeRepo = FakeBookmarkRepository();
    final container = ProviderContainer(overrides: [
      bookmarkRepositoryProvider.overrideWithValue(fakeRepo),
      currentAppUserProvider.overrideWith((ref) async => testStudent),
    ]);
    addTearDown(container.dispose);

    final sub = container.listen(isBookmarkedProvider('opp-1'), (_, __) {});
    addTearDown(sub.close);
    await container.read(currentAppUserProvider.future);
    await container.read(bookmarkedIdsProvider.future);
    expect(sub.read(), isFalse);

    await container.read(bookmarkControllerProvider.notifier).toggle('opp-1');
    await Future<void>.delayed(Duration.zero);
    expect(sub.read(), isTrue);

    await container.read(bookmarkControllerProvider.notifier).toggle('opp-1');
    await Future<void>.delayed(Duration.zero);
    expect(sub.read(), isFalse);
  });
}
