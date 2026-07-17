import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/startup.dart';

abstract class StartupRepository {
  Stream<Startup?> watchStartup(String id);

  /// For the platform-admin verification queue screen.
  Stream<List<Startup>> watchPendingStartups();

  Future<String> registerStartup(Startup startup);

  Future<void> setVerificationStatus({
    required String startupId,
    required VerificationStatus status,
    required String verifiedByUid,
  });
}

class FirestoreStartupRepository implements StartupRepository {
  FirestoreStartupRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('startups');

  @override
  Stream<Startup?> watchStartup(String id) {
    return _col.doc(id).snapshots().map(
          (doc) => doc.exists ? Startup.fromMap(doc.id, doc.data()!) : null,
        );
  }

  @override
  Stream<List<Startup>> watchPendingStartups() {
    return _col
        .where('verificationStatus', isEqualTo: 'pending')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Startup.fromMap(d.id, d.data())).toList());
  }

  @override
  Future<String> registerStartup(Startup startup) async {
    final ref = await _col.add(startup.toMap());
    return ref.id;
  }

  @override
  Future<void> setVerificationStatus({
    required String startupId,
    required VerificationStatus status,
    required String verifiedByUid,
  }) async {
    await _col.doc(startupId).update({
      'verificationStatus': verificationStatusToString(status),
      'verifiedBy': verifiedByUid,
      'verifiedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
