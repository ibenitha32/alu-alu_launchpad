import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alu_launchpad/data/models/app_user.dart';
import 'package:alu_launchpad/data/models/job_application.dart';
import 'package:alu_launchpad/data/models/opportunity.dart';
import 'package:alu_launchpad/providers/application_providers.dart';
import 'package:alu_launchpad/providers/auth_providers.dart';
import 'package:alu_launchpad/providers/repository_providers.dart';

import '../fakes/fake_repositories.dart';

/// These tests exercise the state-management layer (Riverpod notifiers)
/// entirely in-memory, by overriding the repository providers with fakes.
/// This is the payoff of the repository-pattern architecture described in
/// the report: no Firebase project, emulator, or network call is needed to
/// verify the controller logic is correct.
void main() {
  final testStudent = AppUser(
    uid: 'student-1',
    name: 'Amina Hassan',
    email: 'amina@alustudent.com',
    role: UserRole.student,
    createdAt: DateTime(2026, 1, 1),
  );

  test('apply() submits the application through the repository', () async {
    final fakeRepo = FakeApplicationRepository();
    final container = ProviderContainer(overrides: [
      applicationRepositoryProvider.overrideWithValue(fakeRepo),
      currentAppUserProvider.overrideWith((ref) async => testStudent),
    ]);
    addTearDown(container.dispose);

    await container.read(applicationControllerProvider.notifier).apply(
          opportunityId: 'opp-1',
          startupId: 'startup-1',
          coverNote: 'Excited to help build this!',
        );

    final state = container.read(applicationControllerProvider);
    expect(state.hasError, isFalse);
    expect(fakeRepo.submittedApplications, hasLength(1));
    expect(fakeRepo.submittedApplications.first.opportunityId, 'opp-1');
    expect(fakeRepo.submittedApplications.first.studentUid, 'student-1');
  });

  test('apply() surfaces an error and does not call the repository when signed out',
      () async {
    final fakeRepo = FakeApplicationRepository();
    final container = ProviderContainer(overrides: [
      applicationRepositoryProvider.overrideWithValue(fakeRepo),
      currentAppUserProvider.overrideWith((ref) async => null),
    ]);
    addTearDown(container.dispose);

    await container.read(applicationControllerProvider.notifier).apply(
          opportunityId: 'opp-1',
          startupId: 'startup-1',
          coverNote: '',
        );

    final state = container.read(applicationControllerProvider);
    expect(state.hasError, isTrue);
    expect(fakeRepo.submittedApplications, isEmpty);
  });

  test('hasAppliedProvider reflects an application once submitted', () async {
    final fakeRepo = FakeApplicationRepository();
    final container = ProviderContainer(overrides: [
      applicationRepositoryProvider.overrideWithValue(fakeRepo),
      currentAppUserProvider.overrideWith((ref) async => testStudent),
    ]);
    addTearDown(container.dispose);

    // hasAppliedProvider is autoDispose, so it (and everything it depends
    // on) would tear down between reads unless something keeps it alive —
    // container.listen does that for the life of this test.
    final sub = container.listen(hasAppliedProvider('opp-1'), (_, __) {});
    addTearDown(sub.close);

    await container.read(currentAppUserProvider.future);
    await container.read(myApplicationsProvider.future);
    expect(sub.read(), isFalse);

    await container.read(applicationControllerProvider.notifier).apply(
          opportunityId: 'opp-1',
          startupId: 'startup-1',
          coverNote: '',
        );
    // The fake repo's broadcast stream delivers on a microtask; let it settle.
    await Future<void>.delayed(Duration.zero);

    expect(sub.read(), isTrue);
  });

  test('apply() denormalizes the applicant\'s name and skills onto the application',
      () async {
    final fakeRepo = FakeApplicationRepository();
    final skilledStudent = AppUser(
      uid: 'student-2',
      name: 'Jean Mugisha',
      email: 'jean@alustudent.com',
      role: UserRole.student,
      createdAt: DateTime(2026, 1, 1),
      skills: const ['Flutter', 'Dart'],
      portfolioLinks: const ['https://jean.dev'],
    );
    final container = ProviderContainer(overrides: [
      applicationRepositoryProvider.overrideWithValue(fakeRepo),
      currentAppUserProvider.overrideWith((ref) async => skilledStudent),
    ]);
    addTearDown(container.dispose);

    await container.read(applicationControllerProvider.notifier).apply(
          opportunityId: 'opp-1',
          startupId: 'startup-1',
          coverNote: '',
        );

    final application = fakeRepo.submittedApplications.single;
    expect(application.studentName, 'Jean Mugisha');
    expect(application.studentSkills, ['Flutter', 'Dart']);
    expect(application.studentPortfolioLink, 'https://jean.dev');
  });

  test('updateStatus() updates the application and sends a status_change notification',
      () async {
    final fakeAppRepo = FakeApplicationRepository();
    final fakeOppRepo = FakeOpportunityRepository();
    fakeOppRepo.seed(Opportunity(
      id: 'opp-1',
      startupId: 'startup-1',
      startupName: 'Learnify',
      title: 'Flutter Developer',
      description: 'Build the mobile app.',
      category: 'dev',
      postedAt: DateTime(2026, 1, 1),
    ));
    final fakeNotificationRepo = FakeNotificationRepository();

    final container = ProviderContainer(overrides: [
      applicationRepositoryProvider.overrideWithValue(fakeAppRepo),
      opportunityRepositoryProvider.overrideWithValue(fakeOppRepo),
      notificationRepositoryProvider.overrideWithValue(fakeNotificationRepo),
      currentAppUserProvider.overrideWith((ref) async => testStudent),
    ]);
    addTearDown(container.dispose);

    await container.read(applicationControllerProvider.notifier).apply(
          opportunityId: 'opp-1',
          startupId: 'startup-1',
          coverNote: '',
        );
    final application = fakeAppRepo.submittedApplications.single;

    await container
        .read(applicationControllerProvider.notifier)
        .updateStatus(application, ApplicationStatus.shortlisted);

    final state = container.read(applicationControllerProvider);
    expect(state.hasError, isFalse);

    final updated = await fakeAppRepo.watchStudentApplications('student-1').first;
    expect(updated.single.status, ApplicationStatus.shortlisted);

    expect(fakeNotificationRepo.sent, hasLength(1));
    expect(fakeNotificationRepo.sent.first.uid, 'student-1');
    expect(fakeNotificationRepo.sent.first.type, 'status_change');
    expect(fakeNotificationRepo.sent.first.message, contains('Flutter Developer'));
    expect(fakeNotificationRepo.sent.first.message, contains('Shortlisted'));
  });
}
