import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/ad_entity.dart';
import '../../domain/repositories/ads_repository.dart';
import '../datasources/ads_remote_datasource.dart';
import '../models/ad_model.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/utils/result.dart';

class AdsRepositoryImpl implements AdsRepository {
  final AdsRemoteDataSource _dataSource;

  AdsRepositoryImpl(this._dataSource);

  String _mapFirebaseError(dynamic e) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied': return 'ليس لديك صلاحية لهذا الإجراء';
        case 'not-found': return 'العنصر غير موجود';
        case 'unavailable': return 'الخدمة غير متاحة حالياً، حاول مرة أخرى';
        default: return 'حدث خطأ غير متوقع (${e.code})';
      }
    }
    if (e is SocketException) return 'لا يوجد اتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى';
    return 'حدث خطأ غير متوقع';
  }

  @override
  Future<Result<AdsPage>> getAds({Object? lastDoc, int limit = 20, String? stateFilter}) async {
    try {
      final result = await _dataSource.getAds(
        lastDoc: lastDoc as DocumentSnapshot?,
        limit: limit,
        stateFilter: stateFilter,
      );
      return Result.success(AdsPage(
        ads: result.ads.map((m) => m.toEntity()).toList(),
        lastDoc: result.lastDoc,
      ));
    } catch (e) { return Result.failure(_mapFirebaseError(e)); }
  }

  @override
  Future<Result<List<Ad>>> getFeaturedAds() async {
    try {
      final models = await _dataSource.getFeaturedAds();
      return Result.success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return Result.failure(_mapFirebaseError(e)); }
  }

  @override
  Future<Result<Ad?>> getAdById(String id) async {
    try {
      final model = await _dataSource.getAdById(id);
      return Result.success(model?.toEntity());
    } catch (e) { return Result.failure(_mapFirebaseError(e)); }
  }

  @override
  Future<Result<List<Ad>>> getAdsByUser(String userId) async {
    try {
      final models = await _dataSource.getAdsByUser(userId);
      return Result.success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return Result.failure(_mapFirebaseError(e)); }
  }

  @override
  Future<Result<AdsPage>> getAdsByCategory(String category, {Object? lastDoc, int limit = 20}) async {
    try {
      final result = await _dataSource.getAdsByCategory(category, lastDoc: lastDoc as DocumentSnapshot?, limit: limit);
      return Result.success(AdsPage(
        ads: result.ads.map((m) => m.toEntity()).toList(),
        lastDoc: result.lastDoc,
      ));
    } catch (e) { return Result.failure(_mapFirebaseError(e)); }
  }

  @override
  Future<Result<List<Ad>>> searchAds(String query, {String? category, String? location, double? minPrice, double? maxPrice, String? sortBy}) async {
    try {
      final models = await _dataSource.searchAds(query, category: category, location: location, minPrice: minPrice, maxPrice: maxPrice, sortBy: sortBy);
      return Result.success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return Result.failure(_mapFirebaseError(e)); }
  }

  @override
  Future<Result<String>> createAd(Ad ad, List<String> localImagePaths) async {
    try {
      final model = AdModel.fromEntity(ad);
      final adId = await _dataSource.createAd(model, localImagePaths);
      return Result.success(adId);
    } catch (e) { return Result.failure(_mapFirebaseError(e)); }
  }

  @override
  Future<Result<void>> updateAd(Ad ad, List<String> newLocalImagePaths, List<String> removedImageUrls) async {
    try {
      final model = AdModel.fromEntity(ad);
      await _dataSource.updateAd(model, newLocalImagePaths, removedImageUrls);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapFirebaseError(e)); }
  }

  @override
  Future<Result<void>> deleteAd(String adId, String userId) async {
    try {
      await _dataSource.deleteAd(adId);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapFirebaseError(e)); }
  }

  @override
  Future<Result<void>> incrementViewCount(String adId) async {
    try {
      await _dataSource.incrementViewCount(adId);
      return const Result.success(null);
    } catch (e) { return const Result.success(null); }
  }

  @override
  Future<Result<void>> markAsSold(String adId, String userId) async {
    try {
      await _dataSource.markAsSold(adId, userId);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapFirebaseError(e)); }
  }

  @override
  Future<Result<int>> getUserAdCountToday(String userId) async {
    try {
      final count = await _dataSource.getUserAdCountToday(userId);
      return Result.success(count);
    } catch (e) { return const Result.success(0); }
  }

  @override
  Future<Result<List<Ad>>> getAdsByStatus(AdStatus status, {Object? lastDoc, int limit = 20}) async {
    try {
      final models = await _dataSource.getAdsByStatus(status.value, lastDoc: lastDoc as DocumentSnapshot?, limit: limit);
      return Result.success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return Result.failure(_mapFirebaseError(e)); }
  }

  @override
  Future<Result<void>> updateAdStatus(String adId, AdStatus status, {String? rejectionReason}) async {
    try {
      await _dataSource.updateAdStatus(adId, status.value, rejectionReason: rejectionReason);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapFirebaseError(e)); }
  }

  @override
  Future<Result<void>> toggleFeatured(String adId, bool isFeatured) async {
    try {
      await _dataSource.toggleFeatured(adId, isFeatured);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapFirebaseError(e)); }
  }

  @override
  Future<Result<void>> bumpAd(String adId) async {
    try {
      await _dataSource.bumpAd(adId);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapFirebaseError(e)); }
  }

  @override
  Future<Result<void>> requestFeatured(String adId) async {
    try {
      await _dataSource.requestFeatured(adId);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapFirebaseError(e)); }
  }
}
