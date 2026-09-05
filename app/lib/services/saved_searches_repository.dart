import 'package:cloud_firestore/cloud_firestore.dart';

import '../models.dart';

class SavedSearchesRepository {
  SavedSearchesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _savedSearches =>
      _firestore.collection('savedSearches');

  Stream<List<SavedSearch>> savedSearchesFor(String buyerId) {
    return _savedSearches
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SavedSearch.fromFirestore).toList());
  }

  Future<void> save({
    required String buyerId,
    required String query,
    ListingCategory? category,
    int? maxPriceCents,
  }) {
    final search = SavedSearch(
      id: '', // assigned by Firestore
      buyerId: buyerId,
      query: query,
      category: category,
      maxPriceCents: maxPriceCents,
      createdAt: DateTime.now(),
    );
    return _savedSearches.add(search.toCreateMap());
  }

  Future<void> delete(String searchId) => _savedSearches.doc(searchId).delete();
}
