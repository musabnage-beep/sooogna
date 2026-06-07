import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/favorite_ad_model.dart';

class FavoritesRemoteDataSource {
  final FirebaseFirestore _firestore;

  FavoritesRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference _favCol(String uid) => _firestore
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection(AppConstants.favoritesSubcollection);

  Stream<List<FavoriteAdModel>> watchFavorites(String uid) {
    return _favCol(uid)
        .orderBy('savedAt', descending: true)
        .limit(AppConstants.maxFavoritesRead)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FavoriteAdModel.fromDocument(d)).toList());
  }

  Stream<Set<String>> watchFavoriteIds(String uid) {
    return _favCol(uid)
        .orderBy('savedAt', descending: true)
        .limit(AppConstants.maxFavoritesRead)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  Future<void> addFavorite(String uid, FavoriteAdModel fav) async {
    final batch = _firestore.batch();
    batch.set(_favCol(uid).doc(fav.adId), fav.toMap());
    batch.update(
      _firestore.collection(AppConstants.adsCollection).doc(fav.adId),
      {'favoriteCount': FieldValue.increment(1)},
    );
    await batch.commit();
  }

  Future<void> removeFavorite(String uid, String adId) async {
    final batch = _firestore.batch();
    batch.delete(_favCol(uid).doc(adId));
    batch.update(
      _firestore.collection(AppConstants.adsCollection).doc(adId),
      {'favoriteCount': FieldValue.increment(-1)},
    );
    await batch.commit();
  }
}
