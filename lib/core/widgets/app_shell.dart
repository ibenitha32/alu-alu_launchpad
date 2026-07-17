import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/app_user.dart';
import '../../providers/auth_providers.dart';
import '../theme/app_colors.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);
    final location = GoRouterState.of(context).matchedLocation;

    final items = role == UserRole.startupAdmin
        ? const [
            _NavItem('/startup-dashboard', Icons.dashboard_outlined, 'Dashboard'),
            _NavItem('/notifications', Icons.notifications_outlined, 'Alerts'),
            _NavItem('/profile', Icons.person_outline, 'Profile'),
          ]
        : const [
            _NavItem('/home', Icons.home_outlined, 'Home'),
            _NavItem('/applications', Icons.assignment_outlined, 'Applications'),
            _NavItem('/profile', Icons.person_outline, 'Profile'),
          ];

    final currentIndex =
        items.indexWhere((i) => i.path == location).clamp(0, items.length - 1);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => context.go(items[index].path),
        items: items
            .map((i) => BottomNavigationBarItem(
                  icon: Icon(i.icon),
                  label: i.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final String label;
  const _NavItem(this.path, this.icon, this.label);
}
