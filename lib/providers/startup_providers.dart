import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/startup.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

/// The startup owned/administered by the current user, if any (null for
/// students, or for a startup_admin who hasn't registered one yet).
final myStartupProvider = StreamProvider.autoDispose<Startup?>((ref) {
  final user = ref.watch(currentAppUserProvider).value;
  if (user?.startupId == null) return Stream.value(null);
  return ref.watch(startupRepositoryProvider).watchStartup(user!.startupId!);
});

/// Platform-admin-only: startups awaiting verification.
final pendingStartupsProvider =
    StreamProvider.autoDispose<List<Startup>>((ref) {
  return ref.watch(startupRepositoryProvider).watchPendingStartups();
});

class StartupController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String> register(Startup startup) async {
    state = const AsyncLoading();
    late String id;
    state = await AsyncValue.guard(() async {
      id = await ref.read(startupRepositoryProvider).registerStartup(startup);
    });
    return id;
  }

  Future<void> setVerification({
    required String startupId,
    required VerificationStatus status,
  }) async {
    final admin = await ref.read(currentAppUserProvider.future);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(startupRepositoryProvider).setVerificationStatus(
            startupId: startupId,
            status: status,
            verifiedByUid: admin?.uid ?? '',
          ),
    );
  }
}

final startupControllerProvider =
    AsyncNotifierProvider<StartupController, void>(StartupController.new);
