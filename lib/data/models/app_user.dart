import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, startupAdmin, platformAdmin }

UserRole userRoleFromString(String value) {
  switch (value) {
    case 'startup_admin':
      return UserRole.startupAdmin;
    case 'platform_admin':
      return UserRole.platformAdmin;
    default:
      return UserRole.student;
  }
}

String userRoleToString(UserRole role) {
  switch (role) {
    case UserRole.startupAdmin:
      return 'startup_admin';
    case UserRole.platformAdmin:
      return 'platform_admin';
    case UserRole.student:
      return 'student';
  }
}

/// Represents a user document at users/{uid}.
/// Student-only and startup-admin-only fields are nullable since a single
/// collection holds both roles (avoids a join at read time).
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final UserRole role;
  final DateTime createdAt;

  // Student-only fields
  final List<String> skills;
  final String? bio;
  final List<String> portfolioLinks;

  // Startup-admin-only field
  final String? startupId;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.role,
    required this.createdAt,
    this.skills = const [],
    this.bio,
    this.portfolioLinks = const [],
    this.startupId,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      role: userRoleFromString(map['role'] as String? ?? 'student'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      skills: List<String>.from(map['skills'] as List? ?? const []),
      bio: map['bio'] as String?,
      portfolioLinks:
          List<String>.from(map['portfolioLinks'] as List? ?? const []),
      startupId: map['startupId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': userRoleToString(role),
      'createdAt': Timestamp.fromDate(createdAt),
      'skills': skills,
      'bio': bio,
      'portfolioLinks': portfolioLinks,
      'startupId': startupId,
    };
  }

  AppUser copyWith({
    String? name,
    String? photoUrl,
    List<String>? skills,
    String? bio,
    List<String>? portfolioLinks,
    String? startupId,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role,
      createdAt: createdAt,
      skills: skills ?? this.skills,
      bio: bio ?? this.bio,
      portfolioLinks: portfolioLinks ?? this.portfolioLinks,
      startupId: startupId ?? this.startupId,
    );
  }
}
