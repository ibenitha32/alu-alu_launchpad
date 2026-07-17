import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/opportunity.dart';
import '../../../providers/opportunity_providers.dart';
import '../../../providers/startup_providers.dart';

class PostOpportunityScreen extends ConsumerStatefulWidget {
  const PostOpportunityScreen({super.key});

  @override
  ConsumerState<PostOpportunityScreen> createState() =>
      _PostOpportunityScreenState();
}

class _PostOpportunityScreenState
    extends ConsumerState<PostOpportunityScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skillsController = TextEditingController();
  String _category = 'dev';
  Commitment _commitment = Commitment.partTime;
  WorkLocation _location = WorkLocation.remote;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startup = ref.watch(myStartupProvider).value;
    final controllerState = ref.watch(opportunityControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Post Opportunity'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _skillsController,
              decoration: const InputDecoration(
                labelText: 'Skills required (comma separated)',
                hintText: 'Flutter, Dart, Firebase',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'dev', child: Text('Engineering')),
                DropdownMenuItem(value: 'design', child: Text('Design')),
                DropdownMenuItem(value: 'marketing', child: Text('Marketing')),
                DropdownMenuItem(value: 'ops', child: Text('Operations')),
                DropdownMenuItem(value: 'research', child: Text('Research')),
                DropdownMenuItem(value: 'content', child: Text('Content')),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'dev'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Commitment>(
              value: _commitment,
              decoration: const InputDecoration(labelText: 'Commitment'),
              items: const [
                DropdownMenuItem(value: Commitment.partTime, child: Text('Part-time')),
                DropdownMenuItem(value: Commitment.fullTime, child: Text('Full-time')),
                DropdownMenuItem(value: Commitment.projectBased, child: Text('Project-based')),
              ],
              onChanged: (v) => setState(() => _commitment = v ?? Commitment.partTime),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<WorkLocation>(
              value: _location,
              decoration: const InputDecoration(labelText: 'Location'),
              items: const [
                DropdownMenuItem(value: WorkLocation.remote, child: Text('Remote')),
                DropdownMenuItem(value: WorkLocation.onCampus, child: Text('On-campus')),
                DropdownMenuItem(value: WorkLocation.hybrid, child: Text('Hybrid')),
              ],
              onChanged: (v) => setState(() => _location = v ?? WorkLocation.remote),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Publish',
              isLoading: controllerState.isLoading,
              onPressed: startup == null
                  ? null
                  : () async {
                      final opportunity = Opportunity(
                        id: '', // ignored on create — Firestore assigns it
                        startupId: startup.id,
                        startupName: startup.name,
                        startupLogoUrl: startup.logoUrl,
                        title: _titleController.text.trim(),
                        description: _descriptionController.text.trim(),
                        category: _category,
                        skillsRequired: _skillsController.text
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList(),
                        commitment: _commitment,
                        location: _location,
                        postedAt: DateTime.now(),
                      );
                      await ref
                          .read(opportunityControllerProvider.notifier)
                          .create(opportunity);
                      if (context.mounted) context.pop();
                    },
            ),
          ],
        ),
      ),
    );
  }
}
