import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/application_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/opportunity_repository.dart';
import '../data/repositories/startup_repository.dart';

/// Raw SDK instances — kept in their own providers so tests can override
/// just these two and get fully faked-out repositories for free.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// ---- Repository providers ----
// Every screen/notifier depends on these abstract types, never on
// FirestoreOpportunityRepository etc. directly. Swapping backends or
// injecting a fake for tests means overriding only these four lines.

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

final startupRepositoryProvider = Provider<StartupRepository>((ref) {
  return FirestoreStartupRepository(ref.watch(firestoreProvider));
});

final opportunityRepositoryProvider = Provider<OpportunityRepository>((ref) {
  return FirestoreOpportunityRepository(ref.watch(firestoreProvider));
});

final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  return FirestoreApplicationRepository(ref.watch(firestoreProvider));
});
