import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alu_launchpad/data/models/opportunity.dart';
import 'package:alu_launchpad/providers/opportunity_providers.dart';
import 'package:alu_launchpad/providers/repository_providers.dart';

import '../fakes/fake_repositories.dart';

/// Extends the controller-test pattern from application_controller_test.dart
/// to OpportunityController — same fakes, same ProviderContainer-override
/// approach, no Firebase project or emulator required.
void main() {
  Opportunity draftOpportunity({String category = 'dev'}) {
    return Opportunity(
      id: '',
      startupId: 'startup-1',
      startupName: 'Learnify',
      title: 'Flutter Developer',
      description: 'Build the mobile app.',
      category: category,
      skillsRequired: const ['Flutter', 'Dart'],
      postedAt: DateTime(2026, 1, 1),
    );
  }

  test('create() submits the opportunity through the repository and returns its id',
      () async {
    final fakeRepo = FakeOpportunityRepository();
    final container = ProviderContainer(overrides: [
      opportunityRepositoryProvider.overrideWithValue(fakeRepo),
    ]);
    addTearDown(container.dispose);

    final id = await container
        .read(opportunityControllerProvider.notifier)
        .create(draftOpportunity());

    final state = container.read(opportunityControllerProvider);
    expect(state.hasError, isFalse);
    expect(id, isNotEmpty);

    final stored = await fakeRepo.watchOpportunity(id).first;
    expect(stored?.title, 'Flutter Developer');
    expect(stored?.category, OpportunityCategory.engineering.storageValue);
  });

  test(
      'categoryFilterProvider only returns opportunities whose storage value matches — '
      'the regression test for the original label-vs-storage-code mismatch bug',
      () async {
    final fakeRepo = FakeOpportunityRepository();
    fakeRepo.seed(Opportunity(
      id: 'opp-design',
      startupId: 'startup-1',
      startupName: 'Learnify',
      title: 'UX Research Volunteer',
      description: '...',
      category: OpportunityCategory.design.storageValue,
      postedAt: DateTime(2026, 1, 1),
    ));
    fakeRepo.seed(Opportunity(
      id: 'opp-dev',
      startupId: 'startup-1',
      startupName: 'Learnify',
      title: 'Flutter Developer',
      description: '...',
      category: OpportunityCategory.engineering.storageValue,
      postedAt: DateTime(2026, 1, 1),
    ));

    final container = ProviderContainer(overrides: [
      opportunityRepositoryProvider.overrideWithValue(fakeRepo),
    ]);
    addTearDown(container.dispose);

    container.read(categoryFilterProvider.notifier).state =
        OpportunityCategory.design;

    final sub = container.listen(openOpportunitiesProvider, (_, __) {});
    addTearDown(sub.close);
    final result = await container.read(openOpportunitiesProvider.future);

    expect(result, hasLength(1));
    expect(result.first.id, 'opp-design');
  });

  test('closeOpportunity marks the opportunity closed', () async {
    final fakeRepo = FakeOpportunityRepository();
    fakeRepo.seed(Opportunity(
      id: 'opp-1',
      startupId: 'startup-1',
      startupName: 'Learnify',
      title: 'Flutter Developer',
      description: '...',
      category: 'dev',
      postedAt: DateTime(2026, 1, 1),
    ));

    final container = ProviderContainer(overrides: [
      opportunityRepositoryProvider.overrideWithValue(fakeRepo),
    ]);
    addTearDown(container.dispose);

    await container.read(opportunityControllerProvider.notifier).close('opp-1');

    final closed = await fakeRepo.watchOpportunity('opp-1').first;
    expect(closed?.status, OpportunityStatus.closed);
  });
}
