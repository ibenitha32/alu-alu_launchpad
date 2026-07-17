import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/startup.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/startup_providers.dart';

class RegisterStartupScreen extends ConsumerStatefulWidget {
  const RegisterStartupScreen({super.key});

  @override
  ConsumerState<RegisterStartupScreen> createState() =>
      _RegisterStartupScreenState();
}

class _RegisterStartupScreenState extends ConsumerState<RegisterStartupScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sectorController = TextEditingController();
  final _contactEmailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _sectorController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(startupControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Register Startup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your startup will be reviewed by an ALU platform admin before you can post opportunities.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Startup name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sectorController,
              decoration: const InputDecoration(labelText: 'Sector (e.g. Fintech, EdTech)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contactEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Contact email'),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Submit for Review',
              isLoading: controllerState.isLoading,
              onPressed: () async {
                final user = ref.read(currentAppUserProvider).value;
                if (user == null) return;

                final startup = Startup(
                  id: '',
                  name: _nameController.text.trim(),
                  description: _descriptionController.text.trim(),
                  sector: _sectorController.text.trim(),
                  ownerUid: user.uid,
                  adminUids: [user.uid],
                  contactEmail: _contactEmailController.text.trim(),
                  createdAt: DateTime.now(),
                );

                final id = await ref
                    .read(startupControllerProvider.notifier)
                    .register(startup);

                // Link the new startup back onto the user doc so
                // myStartupProvider can find it.
                await ref
                    .read(firestoreProvider)
                    .collection('users')
                    .doc(user.uid)
                    .update({'startupId': id});

                if (context.mounted) context.go('/startup-dashboard');
              },
            ),
          ],
        ),
      ),
    );
  }
}
