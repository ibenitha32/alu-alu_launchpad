import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../models/app_user.dart';

abstract class AuthRepository {
  Stream<fb.User?> authStateChanges();

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  });

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  Future<AppUser?> getCurrentAppUser();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._firestore);

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<fb.User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    final user = AppUser(
      uid: uid,
      name: name,
      email: email,
      role: role,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(uid).set(user.toMap());
    return user;
  }

  @override
  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<AppUser?> getCurrentAppUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }
}
