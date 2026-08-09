import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alu_launchpad/data/models/app_user.dart';
import 'package:alu_launchpad/data/models/startup.dart';
import 'package:alu_launchpad/providers/auth_providers.dart';
import 'package:alu_launchpad/providers/repository_providers.dart';
import 'package:alu_launchpad/providers/startup_providers.dart';

import '../fakes/fake_repositories.dart';

/// Extends the controller-test pattern from application_controller_test.dart
/// to StartupController — including the notification side effect that
/// setVerification() now triggers (Problem 3 of the resubmission).
void main() {
  final testAdmin = AppUser(
    uid: 'admin-1',
    name: 'Platform Admin',
    email: 'admin@alustudent.com',
    role: UserRole.platformAdmin,
    createdAt: DateTime(2026, 1, 1),
  );

  Startup pendingStartup() => Startup(
        id: '',
        name: 'Learnify',
        description: 'EdTech startup',
        sector: 'EdTech',
        ownerUid: 'owner-1',
        adminUids: const ['owner-1'],
        contactEmail: 'owner@learnify.com',
        createdAt: DateTime(2026, 1, 1),
      );

  test('register() submits the startup through the repository and returns its id',
      () async {
    final fakeRepo = FakeStartupRepository();
    final container = ProviderContainer(overrides: [
      startupRepositoryProvider.overrideWithValue(fakeRepo),
    ]);
    addTearDown(container.dispose);

    final id = await container
        .read(startupControllerProvider.notifier)
        .register(pendingStartup());

    expect(id, isNotEmpty);
    final stored = await fakeRepo.watchStartup(id).first;
    expect(stored?.name, 'Learnify');
    expect(stored?.verificationStatus, VerificationStatus.pending);
  });

  test('setVerification() updates status and notifies every startup admin', () async {
    final fakeStartupRepo = FakeStartupRepository();
    fakeStartupRepo.seed(Startup(
      id: 'startup-1',
      name: 'Learnify',
      description: 'EdTech startup',
      sector: 'EdTech',
      ownerUid: 'owner-1',
      adminUids: const ['owner-1', 'owner-2'],
      contactEmail: 'owner@learnify.com',
      createdAt: DateTime(2026, 1, 1),
    ));
    final fakeNotificationRepo = FakeNotificationRepository();

    final container = ProviderContainer(overrides: [
      startupRepositoryProvider.overrideWithValue(fakeStartupRepo),
      notificationRepositoryProvider.overrideWithValue(fakeNotificationRepo),
      currentAppUserProvider.overrideWith((ref) async => testAdmin),
    ]);
    addTearDown(container.dispose);

    await container.read(startupControllerProvider.notifier).setVerification(
          startupId: 'startup-1',
          status: VerificationStatus.verified,
        );

    final state = container.read(startupControllerProvider);
    expect(state.hasError, isFalse);

    final updated = await fakeStartupRepo.watchStartup('startup-1').first;
    expect(updated?.verificationStatus, VerificationStatus.verified);
    expect(updated?.verifiedBy, 'admin-1');

    expect(fakeNotificationRepo.sent, hasLength(2));
    expect(
      fakeNotificationRepo.sent.map((n) => n.uid),
      containsAll(['owner-1', 'owner-2']),
    );
    expect(
      fakeNotificationRepo.sent.every((n) => n.type == 'verification_result'),
      isTrue,
    );
  });
}
