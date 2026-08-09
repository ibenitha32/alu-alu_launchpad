import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/repository_providers.dart';

/// Shown once after a student signs up so recommendations/skill-matching
/// have something to work with immediately. Also reused (with
/// [isEditing]: true) behind Profile → "Skills & Interests" so skills stay
/// editable after onboarding.
class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key, this.isEditing = false});

  final bool isEditing;

  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  static const _baseSuggestions = [
    'Flutter', 'Dart', 'UX Design', 'Research', 'Marketing',
    'Content Writing', 'Data Analysis', 'Business Analysis',
  ];

  late Set<String> _selected;
  late List<String> _options;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final currentSkills = ref.read(currentAppUserProvider).value?.skills ?? const [];
    _selected = {...currentSkills};
    _options = {..._baseSuggestions, ...currentSkills}.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.isEditing
          ? AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              title: const Text('Skills & Interests'),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isEditing) ...[
                Text('What are you good at?', style: AppTextStyles.heading),
                const SizedBox(height: 4),
              ],
              Text('Pick a few skills — this powers your recommendations',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _options.map((skill) {
                  final isSelected = _selected.contains(skill);
                  return FilterChip(
                    label: Text(skill),
                    selected: isSelected,
                    onSelected: (v) => setState(
                      () => v ? _selected.add(skill) : _selected.remove(skill),
                    ),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                  );
                }).toList(),
              ),
              const Spacer(),
              PrimaryButton(
                label: widget.isEditing ? 'Save' : 'Continue',
                isLoading: _saving,
                onPressed: () async {
                  setState(() => _saving = true);
                  final user = ref.read(currentAppUserProvider).value;
                  if (user != null) {
                    await ref.read(firestoreProvider).collection('users').doc(user.uid).update({
                      'skills': _selected.toList(),
                    });
                    ref.invalidate(currentAppUserProvider);
                  }
                  if (!context.mounted) return;
                  if (widget.isEditing) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
