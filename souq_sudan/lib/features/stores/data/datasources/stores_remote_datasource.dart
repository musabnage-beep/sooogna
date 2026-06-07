import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../../ads/data/models/ad_model.dart';
import '../models/store_model.dart';

class StoresRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  StoresRemoteDataSource({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(AppConstants.storesCollection);

  CollectionReference<Map<String, dynamic>> get _adsCol =>
      _firestore.collection('ads');

  Future<StoreModel?> getStoreById(String storeId) async {
    final doc = await _col.doc(storeId).get();
    if (!doc.exists) return null;
    return StoreModel.fromDocument(doc);
  }

  /// The caller's own store (docId == ownerId), live.
  Stream<StoreModel?> watchMyStore(String ownerId) {
    return _col.doc(ownerId).snapshots().map(
          (doc) => doc.exists ? StoreModel.fromDocument(doc) : null,
        );
  }

  /// Products of a store = active ads whose `storeId` matches. Value-based
  /// cursor pagination via the last loaded ad's createdAt.
  Future<List<AdModel>> getStoreProducts(
    String storeId, {
    Timestamp? afterCreatedAt,
    int limit = AppConstants.storeProductsPageSize,
  }) async {
    Query<Map<String, dynamic>> q = _adsCol
        .where('storeId', isEqualTo: storeId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true);
    if (afterCreatedAt != null) q = q.startAfter([afterCreatedAt]);
    final snap = await q.limit(limit).get();
    return snap.docs.map((d) => AdModel.fromDocument(d)).toList();
  }

  Future<String> _uploadImage(
      String storeId, String localPath, String name) async {
    final file = File(localPath);
    final compressed =
        await ImageCompressor.compressToMaxSize(file, AppConstants.maxImageSizeBytes);
    final ref = _storage.ref('store_assets/$storeId/$name.jpg');
    await ref.putFile(compressed);
    final url = await ref.getDownloadURL();
    await ImageCompressor.deleteIfTemp(compressed);
    return url;
  }

  /// Create or update the caller's store (docId == ownerId). rating/ratingCount/
  /// productCount are seeded once on create and never overwritten on update
  /// (they are owned by the review transaction and the product-count counter).
  Future<void> upsertStore(
    StoreModel model, {
    String? newLogoPath,
    String? newBannerPath,
  }) async {
    var logo = model.logo;
    var banner = model.banner;
    if (newLogoPath != null) {
      logo = await _uploadImage(model.storeId, newLogoPath, 'logo');
    }
    if (newBannerPath != null) {
      banner = await _uploadImage(model.storeId, newBannerPath, 'banner');
    }

    final exists = (await _col.doc(model.storeId).get()).exists;

    final data = model.toMap()
      ..['logo'] = logo
      ..['banner'] = banner;

    if (exists) {
      data
        ..remove('rating')
        ..remove('ratingCount')
        ..remove('productCount')
        ..remove('createdAt');
    }

    await _col.doc(model.storeId).set(data, SetOptions(merge: true));
  }
}
