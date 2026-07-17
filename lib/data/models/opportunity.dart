import 'package:cloud_firestore/cloud_firestore.dart';

enum OpportunityStatus { open, closed, draft }
enum Commitment { partTime, fullTime, projectBased }
enum WorkLocation { remote, onCampus, hybrid }

OpportunityStatus _statusFromString(String v) => OpportunityStatus.values
    .firstWhere((e) => e.name == v, orElse: () => OpportunityStatus.draft);

Commitment _commitmentFromString(String v) {
  switch (v) {
    case 'full-time':
      return Commitment.fullTime;
    case 'project-based':
      return Commitment.projectBased;
    default:
      return Commitment.partTime;
  }
}

String _commitmentToString(Commitment c) {
  switch (c) {
    case Commitment.fullTime:
      return 'full-time';
    case Commitment.projectBased:
      return 'project-based';
    case Commitment.partTime:
      return 'part-time';
  }
}

WorkLocation _locationFromString(String v) {
  switch (v) {
    case 'on-campus':
      return WorkLocation.onCampus;
    case 'hybrid':
      return WorkLocation.hybrid;
    default:
      return WorkLocation.remote;
  }
}

String _locationToString(WorkLocation l) {
  switch (l) {
    case WorkLocation.onCampus:
      return 'on-campus';
    case WorkLocation.hybrid:
      return 'hybrid';
    case WorkLocation.remote:
      return 'remote';
  }
}

/// Represents opportunities/{opportunityId}.
/// startupId/startupName/startupLogoUrl are denormalized from the parent
/// Startup document so opportunity list screens don't need N extra reads.
class Opportunity {
  final String id;
  final String startupId;
  final String startupName;
  final String? startupLogoUrl;
  final String title;
  final String description;
  final String category; // dev, design, marketing, ops, research, content...
  final List<String> skillsRequired;
  final Commitment commitment;
  final WorkLocation location;
  final OpportunityStatus status;
  final DateTime postedAt;
  final DateTime? deadline;
  final int applicantCount;

  const Opportunity({
    required this.id,
    required this.startupId,
    required this.startupName,
    this.startupLogoUrl,
    required this.title,
    required this.description,
    required this.category,
    this.skillsRequired = const [],
    this.commitment = Commitment.partTime,
    this.location = WorkLocation.remote,
    this.status = OpportunityStatus.open,
    required this.postedAt,
    this.deadline,
    this.applicantCount = 0,
  });

  /// Simple skill-overlap score against a student's skill list — used for
  /// the "Recommended" section sort order. O(n) client-side, no ML needed.
  int matchScore(List<String> studentSkills) {
    final required = skillsRequired.map((s) => s.toLowerCase()).toSet();
    final have = studentSkills.map((s) => s.toLowerCase()).toSet();
    return required.intersection(have).length;
  }

  factory Opportunity.fromMap(String id, Map<String, dynamic> map) {
    return Opportunity(
      id: id,
      startupId: map['startupId'] as String? ?? '',
      startupName: map['startupName'] as String? ?? '',
      startupLogoUrl: map['startupLogoUrl'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      skillsRequired:
          List<String>.from(map['skillsRequired'] as List? ?? const []),
      commitment: _commitmentFromString(map['commitment'] as String? ?? ''),
      location: _locationFromString(map['location'] as String? ?? ''),
      status: _statusFromString(map['status'] as String? ?? 'open'),
      postedAt: (map['postedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deadline: (map['deadline'] as Timestamp?)?.toDate(),
      applicantCount: (map['applicantCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startupId': startupId,
      'startupName': startupName,
      'startupLogoUrl': startupLogoUrl,
      'title': title,
      'description': description,
      'category': category,
      'skillsRequired': skillsRequired,
      'commitment': _commitmentToString(commitment),
      'location': _locationToString(location),
      'status': status.name,
      'postedAt': Timestamp.fromDate(postedAt),
      'deadline': deadline == null ? null : Timestamp.fromDate(deadline!),
      'applicantCount': applicantCount,
    };
  }
}
