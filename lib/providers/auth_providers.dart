import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_user.dart';
import 'repository_providers.dart';

/// Raw Firebase auth state — null when signed out.
final authStateProvider = StreamProvider<fb.User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// The resolved app-level user document (with role, skills, startupId, etc).
/// Re-fetches whenever the underlying auth state changes.
final currentAppUserProvider = FutureProvider<AppUser?>((ref) async {
  final fbUser = await ref.watch(authStateProvider.future);
  if (fbUser == null) return null;
  return ref.watch(authRepositoryProvider).getCurrentAppUser();
});

/// Convenience bool providers used by the router guard and UI.
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).value != null;
});

final currentUserRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(currentAppUserProvider).value?.role;
});

/// Notifier exposing sign-in/sign-up/sign-out actions with loading/error state.
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          ),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signUp(
            email: email,
            password: password,
            name: name,
            role: role,
          ),
    );
    ref.invalidate(currentAppUserProvider);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
