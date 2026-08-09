import 'package:cloud_firestore/cloud_firestore.dart';

/// Abstract interface — same rationale as the other repositories: providers
/// depend on this, not on Firestore directly, so it's swappable for tests.
abstract class BookmarkRepository {
  /// Real-time set of opportunity IDs the given user has bookmarked.
  Stream<Set<String>> watchBookmarkedIds(String uid);

  /// Adds the bookmark if [isBookmarked] is false, removes it otherwise.
  Future<void> toggleBookmark({
    required String uid,
    required String opportunityId,
    required bool isBookmarked,
  });
}

class FirestoreBookmarkRepository implements BookmarkRepository {
  FirestoreBookmarkRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _itemsCol(String uid) => _firestore
      .collection('bookmarks')
      .doc(uid)
      .collection('items');

  @override
  Stream<Set<String>> watchBookmarkedIds(String uid) {
    return _itemsCol(uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  @override
  Future<void> toggleBookmark({
    required String uid,
    required String opportunityId,
    required bool isBookmarked,
  }) async {
    final doc = _itemsCol(uid).doc(opportunityId);
    if (isBookmarked) {
      await doc.delete();
    } else {
      await doc.set({'bookmarkedAt': FieldValue.serverTimestamp()});
    }
  }
}
