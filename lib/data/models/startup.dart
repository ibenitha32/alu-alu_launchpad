import 'package:cloud_firestore/cloud_firestore.dart';

enum VerificationStatus { pending, verified, rejected }

VerificationStatus verificationStatusFromString(String value) {
  switch (value) {
    case 'verified':
      return VerificationStatus.verified;
    case 'rejected':
      return VerificationStatus.rejected;
    default:
      return VerificationStatus.pending;
  }
}

String verificationStatusToString(VerificationStatus status) {
  switch (status) {
    case VerificationStatus.verified:
      return 'verified';
    case VerificationStatus.rejected:
      return 'rejected';
    case VerificationStatus.pending:
      return 'pending';
  }
}

/// Represents a startup document at startups/{startupId}.
/// verificationStatus is the gate that keeps unverified orgs from posting
/// (enforced again server-side in Firestore Security Rules, not just here).
class Startup {
  final String id;
  final String name;
  final String? logoUrl;
  final String description;
  final String sector;
  final VerificationStatus verificationStatus;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String ownerUid;
  final List<String> adminUids;
  final String contactEmail;
  final DateTime createdAt;

  const Startup({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.description,
    required this.sector,
    this.verificationStatus = VerificationStatus.pending,
    this.verifiedBy,
    this.verifiedAt,
    required this.ownerUid,
    this.adminUids = const [],
    required this.contactEmail,
    required this.createdAt,
  });

  bool get isVerified => verificationStatus == VerificationStatus.verified;

  factory Startup.fromMap(String id, Map<String, dynamic> map) {
    return Startup(
      id: id,
      name: map['name'] as String? ?? '',
      logoUrl: map['logoUrl'] as String?,
      description: map['description'] as String? ?? '',
      sector: map['sector'] as String? ?? '',
      verificationStatus: verificationStatusFromString(
          map['verificationStatus'] as String? ?? 'pending'),
      verifiedBy: map['verifiedBy'] as String?,
      verifiedAt: (map['verifiedAt'] as Timestamp?)?.toDate(),
      ownerUid: map['ownerUid'] as String? ?? '',
      adminUids: List<String>.from(map['adminUids'] as List? ?? const []),
      contactEmail: map['contactEmail'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'description': description,
      'sector': sector,
      'verificationStatus': verificationStatusToString(verificationStatus),
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt == null ? null : Timestamp.fromDate(verifiedAt!),
      'ownerUid': ownerUid,
      'adminUids': adminUids,
      'contactEmail': contactEmail,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
