import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/app_user.dart';
import '../../features/applications/presentation/my_applications_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/role_select_screen.dart';
import '../../features/opportunity_detail/presentation/opportunity_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/startup_dashboard/presentation/applicant_list_screen.dart';
import '../../features/startup_dashboard/presentation/dashboard_screen.dart';
import '../../features/startup_dashboard/presentation/post_opportunity_screen.dart';
import '../../features/startup_verification/presentation/admin_verification_queue_screen.dart';
import '../../features/startup_verification/presentation/register_startup_screen.dart';
import '../../features/student_home/presentation/home_screen.dart';
import '../widgets/app_shell.dart';
import '../../providers/auth_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final isSignedIn = ref.watch(isSignedInProvider);
  final role = ref.watch(currentUserRoleProvider);

  return GoRouter(
    initialLocation: '/sign-in',
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/sign-in' ||
          state.matchedLocation == '/sign-up';

      if (!isSignedIn && !loggingIn) return '/sign-in';
      if (isSignedIn && loggingIn) return _homeForRole(role);
      return null;
    },
    routes: [
      GoRoute(path: '/sign-in', builder: (c, s) => const SignInScreen()),
      GoRoute(path: '/sign-up', builder: (c, s) => const SignUpScreen()),
      GoRoute(
          path: '/onboarding', builder: (c, s) => const RoleSelectScreen()),

      // Student & startup-admin shared shell (bottom nav)
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
          GoRoute(
            path: '/applications',
            builder: (c, s) => const MyApplicationsScreen(),
          ),
          GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
          GoRoute(
            path: '/notifications',
            builder: (c, s) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/startup-dashboard',
            builder: (c, s) => const DashboardScreen(),
          ),
        ],
      ),

      GoRoute(
        path: '/opportunity/:id',
        builder: (c, s) =>
            OpportunityDetailScreen(opportunityId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/startup-dashboard/post',
        builder: (c, s) => const PostOpportunityScreen(),
      ),
      GoRoute(
        path: '/startup-dashboard/applicants/:opportunityId',
        builder: (c, s) => ApplicantListScreen(
          opportunityId: s.pathParameters['opportunityId']!,
        ),
      ),
      GoRoute(
        path: '/register-startup',
        builder: (c, s) => const RegisterStartupScreen(),
      ),
      GoRoute(
        path: '/admin/verification-queue',
        builder: (c, s) => const AdminVerificationQueueScreen(),
      ),
    ],
  );
});

String _homeForRole(UserRole? role) {
  switch (role) {
    case UserRole.startupAdmin:
      return '/startup-dashboard';
    case UserRole.platformAdmin:
      return '/admin/verification-queue';
    case UserRole.student:
    case null:
      return '/home';
  }
}
