import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/ad_model.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../../../core/constants/app_constants.dart';

class AdsRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  AdsRemoteDataSource({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  CollectionReference get _adsRef => _firestore.collection('ads');

  Future<List<AdModel>> getAds({DocumentSnapshot? lastDoc, int limit = 20}) async {
    Query query = _adsRef
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (lastDoc != null) query = query.startAfterDocument(lastDoc);
    final snap = await query.get();
    return snap.docs.map((d) => AdModel.fromDocument(d)).toList();
  }

  Future<DocumentSnapshot?> getLastDocForAds({int limit = 20}) async {
    final snap = await _adsRef
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.isNotEmpty ? snap.docs.last : null;
  }

  Future<List<AdModel>> getFeaturedAds() async {
    final snap = await _adsRef
        .where('isFeatured', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();
    return snap.docs.map((d) => AdModel.fromDocument(d)).toList();
  }

  Future<AdModel?> getAdById(String id) async {
    final doc = await _adsRef.doc(id).get();
    if (!doc.exists) return null;
    return AdModel.fromDocument(doc);
  }

  Future<List<AdModel>> getAdsByUser(String userId) async {
    final snap = await _adsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => AdModel.fromDocument(d)).toList();
  }

  Future<List<AdModel>> getAdsByCategory(String category, {DocumentSnapshot? lastDoc, int limit = 20}) async {
    Query query = _adsRef
        .where('category', isEqualTo: category)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (lastDoc != null) query = query.startAfterDocument(lastDoc);
    final snap = await query.get();
    return snap.docs.map((d) => AdModel.fromDocument(d)).toList();
  }

  Future<List<AdModel>> searchAds(String query, {String? category, String? location, double? minPrice, double? maxPrice, String? sortBy}) async {
    // Search using searchKeywords array-contains-any
    final keywords = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length >= 2).take(10).toList();

    Query q = _adsRef.where('status', isEqualTo: 'active');

    if (keywords.isNotEmpty) {
      q = q.where('searchKeywords', arrayContainsAny: keywords);
    }
    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }
    if (location != null && location.isNotEmpty) {
      q = q.where('location', isEqualTo: location);
    }

    // Apply sort - only when not using arrayContainsAny with price (Firestore limitation)
    if (keywords.isEmpty) {
      if (sortBy == 'price_asc') {
        q = q.orderBy('price').orderBy('createdAt', descending: true);
      } else if (sortBy == 'price_desc') {
        q = q.orderBy('price', descending: true).orderBy('createdAt', descending: true);
      } else {
        q = q.orderBy('createdAt', descending: true);
      }
      if (minPrice != null) q = q.where('price', isGreaterThanOrEqualTo: minPrice);
      if (maxPrice != null) q = q.where('price', isLessThanOrEqualTo: maxPrice);
    }

    final snap = await q.limit(50).get();
    var results = snap.docs.map((d) => AdModel.fromDocument(d)).toList();

    // Client-side filter for price when using text search
    if (keywords.isNotEmpty) {
      if (minPrice != null) results = results.where((a) => a.price >= minPrice).toList();
      if (maxPrice != null) results = results.where((a) => a.price <= maxPrice).toList();
      if (sortBy == 'price_asc') results.sort((a, b) => a.price.compareTo(b.price));
      else if (sortBy == 'price_desc') results.sort((a, b) => b.price.compareTo(a.price));
      else results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return results;
  }

  Future<String> createAd(AdModel model, List<String> localImagePaths) async {
    final adRef = _adsRef.doc();
    final adId = adRef.id;

    final imageUrls = <String>[];
    for (int i = 0; i < localImagePaths.length; i++) {
      final file = File(localImagePaths[i]);
      final compressed = await ImageCompressor.compressToMaxSize(file, AppConstants.maxImageSizeBytes);
      final ref = _storage.ref('ad_images/$adId/$i.jpg');
      await ref.putFile(compressed);
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }

    final updatedModel = AdModel(
      id: adId,
      title: model.title,
      description: model.description,
      price: model.price,
      category: model.category,
      images: imageUrls,
      userId: model.userId,
      userName: model.userName,
      userPhone: model.userPhone,
      location: model.location,
      isFeatured: false,
      status: 'pending',
      searchKeywords: model.searchKeywords,
      createdAt: model.createdAt,
    );

    await adRef.set(updatedModel.toMap());
    return adId;
  }

  Future<void> updateAd(AdModel model, List<String> newLocalImagePaths, List<String> removedImageUrls) async {
    // Delete removed images from storage
    for (final url in removedImageUrls) {
      try {
        await _storage.refFromURL(url).delete();
      } catch (_) {}
    }

    // Upload new images
    final newUrls = <String>[];
    final existingImages = model.images.where((url) => !removedImageUrls.contains(url)).toList();

    for (int i = 0; i < newLocalImagePaths.length; i++) {
      final file = File(newLocalImagePaths[i]);
      final compressed = await ImageCompressor.compressToMaxSize(file, AppConstants.maxImageSizeBytes);
      final idx = existingImages.length + i;
      final ref = _storage.ref('ad_images/${model.id}/$idx.jpg');
      await ref.putFile(compressed);
      final url = await ref.getDownloadURL();
      newUrls.add(url);
    }

    final allImages = [...existingImages, ...newUrls];

    await _adsRef.doc(model.id).update({
      'title': model.title,
      'description': model.description,
      'price': model.price,
      'category': model.category,
      'images': allImages,
      'location': model.location,
      'searchKeywords': model.searchKeywords,
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'pending', // back to pending after edit
    });
  }

  Future<void> deleteAd(String adId) async {
    // Delete images from storage
    try {
      final storageRef = _storage.ref('ad_images/$adId');
      final listResult = await storageRef.listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (_) {}
    await _adsRef.doc(adId).delete();
  }

  Future<void> incrementViewCount(String adId) async {
    await _adsRef.doc(adId).update({'viewCount': FieldValue.increment(1)});
  }

  Future<void> markAsSold(String adId, String userId) async {
    await _adsRef.doc(adId).update({
      'status': 'sold',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int> getUserAdCountToday(String userId) async {
    final midnight = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    final snap = await _adsRef
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(midnight))
        .get();
    return snap.docs.length;
  }

  Future<List<AdModel>> getAdsByStatus(String status, {DocumentSnapshot? lastDoc, int limit = 20}) async {
    Query query = _adsRef
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (lastDoc != null) query = query.startAfterDocument(lastDoc);
    final snap = await query.get();
    return snap.docs.map((d) => AdModel.fromDocument(d)).toList();
  }

  Future<DocumentSnapshot?> getLastDocumentFromQuery(Query query) async {
    final snap = await query.get();
    return snap.docs.isNotEmpty ? snap.docs.last : null;
  }

  Future<void> updateAdStatus(String adId, String status, {String? rejectionReason}) async {
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == 'active') data['rejectionReason'] = null;
    if (rejectionReason != null) data['rejectionReason'] = rejectionReason;
    await _adsRef.doc(adId).update(data);
  }

  Future<void> toggleFeatured(String adId, bool isFeatured) async {
    await _adsRef.doc(adId).update({'isFeatured': isFeatured});
  }
}
