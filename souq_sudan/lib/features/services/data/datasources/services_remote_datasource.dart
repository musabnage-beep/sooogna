import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/image_compressor.dart';
import '../models/service_model.dart';

class ServicesRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ServicesRemoteDataSource({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(AppConstants.servicesCollection);

  /// Browse active service providers, optionally filtered by profession/city,
  /// ordered by rating then newest. Value-based cursor pagination: pass the
  /// last loaded provider's [afterRating]/[afterCreatedAt] to fetch the next page.
  Future<List<ServiceModel>> getServices({
    String? profession,
    String? city,
    double? afterRating,
    Timestamp? afterCreatedAt,
    int limit = AppConstants.servicesPageSize,
  }) async {
    Query<Map<String, dynamic>> q = _col.where('isActive', isEqualTo: true);
    if (profession != null && profession.isNotEmpty) {
      q = q.where('profession', isEqualTo: profession);
    }
    if (city != null && city.isNotEmpty) {
      q = q.where('city', isEqualTo: city);
    }
    q = q.orderBy('rating', descending: true).orderBy('createdAt', descending: true);
    if (afterRating != null && afterCreatedAt != null) {
      q = q.startAfter([afterRating, afterCreatedAt]);
    }
    final snap = await q.limit(limit).get();
    return snap.docs.map((d) => ServiceModel.fromDocument(d)).toList();
  }

  Future<List<ServiceModel>> searchServices(String query) async {
    final keywords = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2)
        .take(10)
        .toList();
    Query<Map<String, dynamic>> q = _col.where('isActive', isEqualTo: true);
    if (keywords.isNotEmpty) {
      q = q.where('searchKeywords', arrayContainsAny: keywords);
    }
    final snap = await q.limit(50).get();
    return snap.docs.map((d) => ServiceModel.fromDocument(d)).toList();
  }

  Future<ServiceModel?> getServiceById(String userId) async {
    final doc = await _col.doc(userId).get();
    if (!doc.exists) return null;
    return ServiceModel.fromDocument(doc);
  }

  Stream<ServiceModel?> watchMyService(String userId) {
    return _col.doc(userId).snapshots().map(
          (doc) => doc.exists ? ServiceModel.fromDocument(doc) : null,
        );
  }

  /// Upload a single image to the provider's portfolio storage path.
  Future<String> _uploadImage(String userId, String localPath, String name) async {
    final file = File(localPath);
    final compressed =
        await ImageCompressor.compressToMaxSize(file, AppConstants.maxImageSizeBytes);
    final ref = _storage.ref('service_portfolio/$userId/$name.jpg');
    await ref.putFile(compressed);
    final url = await ref.getDownloadURL();
    await ImageCompressor.deleteIfTemp(compressed);
    return url;
  }

  /// Create or update the caller's service profile (doc id == userId).
  /// [newProfileImagePath]/[newPortfolioPaths] are local files to upload;
  /// already-uploaded URLs in [model] are preserved.
  Future<void> upsertService(
    ServiceModel model, {
    String? newProfileImagePath,
    List<String> newPortfolioPaths = const [],
  }) async {
    var profileImage = model.profileImage;
    if (newProfileImagePath != null) {
      profileImage = await _uploadImage(model.userId, newProfileImagePath, 'profile');
    }

    final portfolio = <String>[...model.portfolioImages];
    for (var i = 0; i < newPortfolioPaths.length; i++) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final url = await _uploadImage(model.userId, newPortfolioPaths[i], 'p_${ts}_$i');
      portfolio.add(url);
    }

    final exists = (await _col.doc(model.userId).get()).exists;

    final data = model.toMap()
      ..['profileImage'] = profileImage
      ..['portfolioImages'] = portfolio;

    // rating/ratingCount/verifiedStatus are owned by the review transaction and
    // admin. Seed them once on create (so orderBy('rating') includes the doc),
    // but never overwrite them on update.
    if (exists) {
      data
        ..remove('rating')
        ..remove('ratingCount')
        ..remove('verifiedStatus')
        ..remove('createdAt');
    }

    await _col.doc(model.userId).set(data, SetOptions(merge: true));
  }

  Future<void> setActive(String userId, bool isActive) async {
    await _col.doc(userId).update({'isActive': isActive});
  }
}
