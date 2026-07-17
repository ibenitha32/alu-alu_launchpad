import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/job_application.dart';

abstract class ApplicationRepository {
  Stream<List<JobApplication>> watchStudentApplications(String studentUid);

  Stream<List<JobApplication>> watchOpportunityApplications(
      String opportunityId);

  Future<void> submitApplication({
    required String opportunityId,
    required String studentUid,
    required String startupId,
    required String coverNote,
  });

  Future<void> updateStatus(String applicationId, ApplicationStatus status);
}

class FirestoreApplicationRepository implements ApplicationRepository {
  FirestoreApplicationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('applications');

  @override
  Stream<List<JobApplication>> watchStudentApplications(String studentUid) {
    return _col
        .where('studentUid', isEqualTo: studentUid)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => JobApplication.fromMap(d.id, d.data())).toList());
  }

  @override
  Stream<List<JobApplication>> watchOpportunityApplications(
      String opportunityId) {
    return _col
        .where('opportunityId', isEqualTo: opportunityId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => JobApplication.fromMap(d.id, d.data())).toList());
  }

  @override
  Future<void> submitApplication({
    required String opportunityId,
    required String studentUid,
    required String startupId,
    required String coverNote,
  }) async {
    final now = DateTime.now();
    final oppRef = _firestore.collection('opportunities').doc(opportunityId);
    final appRef = _col.doc(); // pre-generated id

    // Transaction: create the application AND bump applicantCount atomically,
    // so the denormalized counter on the opportunity never drifts out of sync.
    await _firestore.runTransaction((tx) async {
      final oppSnap = await tx.get(oppRef);
      final currentCount =
          (oppSnap.data()?['applicantCount'] as num?)?.toInt() ?? 0;

      tx.set(appRef, {
        'opportunityId': opportunityId,
        'studentUid': studentUid,
        'startupId': startupId,
        'status': 'applied',
        'coverNote': coverNote,
        'appliedAt': Timestamp.fromDate(now),
        'statusUpdatedAt': Timestamp.fromDate(now),
        'statusHistory': [
          {'status': 'applied', 'timestamp': Timestamp.fromDate(now)}
        ],
      });

      tx.update(oppRef, {'applicantCount': currentCount + 1});
    });
  }

  @override
  Future<void> updateStatus(
      String applicationId, ApplicationStatus status) async {
    final now = DateTime.now();
    final statusStr = applicationStatusToString(status);
    await _col.doc(applicationId).update({
      'status': statusStr,
      'statusUpdatedAt': Timestamp.fromDate(now),
      'statusHistory': FieldValue.arrayUnion([
        {'status': statusStr, 'timestamp': Timestamp.fromDate(now)}
      ]),
    });
  }
}
