import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/job_application.dart';
import 'auth_providers.dart';
import 'opportunity_providers.dart';
import 'repository_providers.dart';

/// Real-time list of the signed-in student's own applications — powers the
/// tabbed "My Applications" screen (Applied / Interview / Accepted / All).
final myApplicationsProvider =
    StreamProvider.autoDispose<List<JobApplication>>((ref) {
  final user = ref.watch(currentAppUserProvider).value;
  if (user == null) return const Stream.empty();
  return ref
      .watch(applicationRepositoryProvider)
      .watchStudentApplications(user.uid);
});

/// Real-time applicant list for a single opportunity — powers the startup's
/// applicant review screen.
final opportunityApplicantsProvider =
    StreamProvider.autoDispose.family<List<JobApplication>, String>(
        (ref, opportunityId) {
  return ref
      .watch(applicationRepositoryProvider)
      .watchOpportunityApplications(opportunityId);
});

/// Whether the current student has already applied to a given opportunity —
/// derived from myApplicationsProvider so it stays in sync without an
/// extra query, and disables the "Apply Now" button appropriately.
final hasAppliedProvider = Provider.autoDispose.family<bool, String>(
  (ref, opportunityId) {
    final apps = ref.watch(myApplicationsProvider).value ?? const [];
    return apps.any((a) => a.opportunityId == opportunityId);
  },
);

class ApplicationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> apply({
    required String opportunityId,
    required String startupId,
    required String coverNote,
  }) async {
    final user = await ref.read(currentAppUserProvider.future);
    if (user == null) {
      state = AsyncError('You must be signed in to apply', StackTrace.current);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(applicationRepositoryProvider).submitApplication(
            opportunityId: opportunityId,
            studentUid: user.uid,
            startupId: startupId,
            coverNote: coverNote,
            studentName: user.name,
            studentSkills: user.skills,
            studentPortfolioLink:
                user.portfolioLinks.isNotEmpty ? user.portfolioLinks.first : null,
          ),
    );
  }

  /// Takes the full [application] (rather than just its id) because the
  /// student-facing notification needs to know who to notify and what
  /// opportunity changed — data the caller already has on hand.
  Future<void> updateStatus(
      JobApplication application, ApplicationStatus status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(applicationRepositoryProvider)
          .updateStatus(application.id, status);

      final opportunity = await ref
          .read(opportunityRepositoryProvider)
          .watchOpportunity(application.opportunityId)
          .first;

      await ref.read(notificationRepositoryProvider).notify(
            uid: application.studentUid,
            type: 'status_change',
            message:
                'Your application for "${opportunity?.title ?? 'an opportunity'}" '
                'is now ${_statusLabel(status)}.',
          );
    });
  }
}

String _statusLabel(ApplicationStatus status) {
  switch (status) {
    case ApplicationStatus.applied:
      return 'Applied';
    case ApplicationStatus.underReview:
      return 'Under Review';
    case ApplicationStatus.shortlisted:
      return 'Shortlisted';
    case ApplicationStatus.interview:
      return 'Interview';
    case ApplicationStatus.accepted:
      return 'Accepted';
    case ApplicationStatus.rejected:
      return 'Rejected';
  }
}

final applicationControllerProvider =
    AsyncNotifierProvider<ApplicationController, void>(
        ApplicationController.new);
