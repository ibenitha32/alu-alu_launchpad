import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/opportunity.dart';

/// Abstract interface — the state-management layer (Riverpod providers)
/// depends on this, not on Firestore directly. This is what lets you:
///   1. Swap backends later without touching UI/providers.
///   2. Unit-test notifiers with a FakeOpportunityRepository, no emulator needed.
abstract class OpportunityRepository {
  /// Real-time stream of open opportunities, optionally filtered.
  Stream<List<Opportunity>> watchOpenOpportunities({String? category});

  Stream<Opportunity?> watchOpportunity(String id);

  Stream<List<Opportunity>> watchStartupOpportunities(String startupId);

  Future<String> createOpportunity(Opportunity opportunity);

  Future<void> updateOpportunity(String id, Map<String, dynamic> changes);

  Future<void> closeOpportunity(String id);
}

class FirestoreOpportunityRepository implements OpportunityRepository {
  FirestoreOpportunityRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('opportunities');

  @override
  Stream<List<Opportunity>> watchOpenOpportunities({String? category}) {
    Query<Map<String, dynamic>> query =
        _col.where('status', isEqualTo: 'open').orderBy('postedAt', descending: true);
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map(
          (snap) => snap.docs
              .map((d) => Opportunity.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Stream<Opportunity?> watchOpportunity(String id) {
    return _col.doc(id).snapshots().map(
          (doc) => doc.exists ? Opportunity.fromMap(doc.id, doc.data()!) : null,
        );
  }

  @override
  Stream<List<Opportunity>> watchStartupOpportunities(String startupId) {
    return _col
        .where('startupId', isEqualTo: startupId)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Opportunity.fromMap(d.id, d.data())).toList());
  }

  @override
  Future<String> createOpportunity(Opportunity opportunity) async {
    final ref = await _col.add(opportunity.toMap());
    return ref.id;
  }

  @override
  Future<void> updateOpportunity(
      String id, Map<String, dynamic> changes) async {
    await _col.doc(id).update(changes);
  }

  @override
  Future<void> closeOpportunity(String id) async {
    await _col.doc(id).update({'status': 'closed'});
  }
}
