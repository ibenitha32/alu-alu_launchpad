import 'package:cloud_firestore/cloud_firestore.dart';

enum ApplicationStatus {
  applied,
  underReview,
  shortlisted,
  interview,
  accepted,
  rejected,
}

ApplicationStatus applicationStatusFromString(String v) {
  switch (v) {
    case 'under_review':
      return ApplicationStatus.underReview;
    case 'shortlisted':
      return ApplicationStatus.shortlisted;
    case 'interview':
      return ApplicationStatus.interview;
    case 'accepted':
      return ApplicationStatus.accepted;
    case 'rejected':
      return ApplicationStatus.rejected;
    default:
      return ApplicationStatus.applied;
  }
}

String applicationStatusToString(ApplicationStatus s) {
  switch (s) {
    case ApplicationStatus.underReview:
      return 'under_review';
    case ApplicationStatus.shortlisted:
      return 'shortlisted';
    case ApplicationStatus.interview:
      return 'interview';
    case ApplicationStatus.accepted:
      return 'accepted';
    case ApplicationStatus.rejected:
      return 'rejected';
    case ApplicationStatus.applied:
      return 'applied';
  }
}

class StatusEvent {
  final ApplicationStatus status;
  final DateTime timestamp;

  const StatusEvent({required this.status, required this.timestamp});

  factory StatusEvent.fromMap(Map<String, dynamic> map) => StatusEvent(
        status: applicationStatusFromString(map['status'] as String? ?? ''),
        timestamp:
            (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'status': applicationStatusToString(status),
        'timestamp': Timestamp.fromDate(timestamp),
      };
}

/// Represents applications/{applicationId}.
/// startupId is denormalized so a startup admin can query
/// "all applications to my org" without fanning out per opportunity.
class JobApplication {
  final String id;
  final String opportunityId;
  final String studentUid;
  final String startupId;
  final ApplicationStatus status;
  final String coverNote;
  final DateTime appliedAt;
  final DateTime statusUpdatedAt;
  final List<StatusEvent> statusHistory;

  const JobApplication({
    required this.id,
    required this.opportunityId,
    required this.studentUid,
    required this.startupId,
    this.status = ApplicationStatus.applied,
    this.coverNote = '',
    required this.appliedAt,
    required this.statusUpdatedAt,
    this.statusHistory = const [],
  });

  factory JobApplication.fromMap(String id, Map<String, dynamic> map) {
    return JobApplication(
      id: id,
      opportunityId: map['opportunityId'] as String? ?? '',
      studentUid: map['studentUid'] as String? ?? '',
      startupId: map['startupId'] as String? ?? '',
      status: applicationStatusFromString(map['status'] as String? ?? ''),
      coverNote: map['coverNote'] as String? ?? '',
      appliedAt: (map['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statusUpdatedAt:
          (map['statusUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statusHistory: (map['statusHistory'] as List? ?? const [])
          .map((e) => StatusEvent.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'opportunityId': opportunityId,
      'studentUid': studentUid,
      'startupId': startupId,
      'status': applicationStatusToString(status),
      'coverNote': coverNote,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'statusUpdatedAt': Timestamp.fromDate(statusUpdatedAt),
      'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
    };
  }
}
