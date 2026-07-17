import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/application_providers.dart';
import '../../../providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider).value;
    final applications = ref.watch(myApplicationsProvider).value ?? const [];

    final shortlisted = applications
        .where((a) =>
            a.status.name == 'shortlisted' || a.status.name == 'interview')
        .length;
    final accepted =
        applications.where((a) => a.status.name == 'accepted').length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Profile', style: AppTextStyles.heading),
              const Icon(Icons.settings_outlined),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(
                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 28, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(user?.name ?? '', style: AppTextStyles.sectionTitle),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatBlock(label: 'Applications', value: '${applications.length}'),
              _StatBlock(label: 'Shortlisted', value: '$shortlisted'),
              _StatBlock(label: 'Accepted', value: '$accepted'),
            ],
          ),
          const SizedBox(height: 28),
          _MenuTile(icon: Icons.person_outline, label: 'My Profile', onTap: () {}),
          _MenuTile(icon: Icons.star_border, label: 'Skills & Interests', onTap: () {}),
          _MenuTile(icon: Icons.bookmark_border, label: 'Saved Opportunities', onTap: () {}),
          _MenuTile(
            icon: Icons.notifications_none,
            label: 'Notifications',
            onTap: () => context.push('/notifications'),
          ),
          _MenuTile(icon: Icons.help_outline, label: 'Help & Support', onTap: () {}),
          _MenuTile(
            icon: Icons.logout,
            label: 'Logout',
            isDestructive: true,
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.heading),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : AppColors.textPrimary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label, style: AppTextStyles.body.copyWith(color: color)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
