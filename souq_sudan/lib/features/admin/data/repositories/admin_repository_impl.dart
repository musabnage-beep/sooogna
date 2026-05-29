import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';
import '../../../ads/domain/entities/ad_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/utils/result.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _dataSource;
  AdminRepositoryImpl(this._dataSource);

  String _mapError(dynamic e) {
    if (e is FirebaseException) return 'حدث خطأ (${e.code})';
    if (e is SocketException) return 'لا يوجد اتصال بالإنترنت';
    return 'حدث خطأ غير متوقع';
  }

  @override
  Future<Result<DashboardStats>> getDashboardStats() async {
    try {
      final stats = await _dataSource.getDashboardStats();
      return Result.success(DashboardStats(
        totalUsers: stats['totalUsers'] ?? 0,
        totalAds: stats['totalAds'] ?? 0,
        activeAds: stats['activeAds'] ?? 0,
        pendingAds: stats['pendingAds'] ?? 0,
        unresolvedReports: stats['unresolvedReports'] ?? 0,
        adsPostedToday: stats['adsPostedToday'] ?? 0,
      ));
    } catch (e) { return Result.failure(_mapError(e)); }
  }

  @override
  Future<Result<List<AppUser>>> getAllUsers({Object? lastDoc, int limit = 20}) async {
    try {
      final models = await _dataSource.getAllUsers(lastDoc: lastDoc as DocumentSnapshot?, limit: limit);
      return Result.success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return Result.failure(_mapError(e)); }
  }

  @override
  Future<Result<void>> banUser(String userId, String reason) async {
    try {
      await _dataSource.banUser(userId, reason);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapError(e)); }
  }

  @override
  Future<Result<void>> unbanUser(String userId) async {
    try {
      await _dataSource.unbanUser(userId);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapError(e)); }
  }

  @override
  Future<Result<void>> verifyUser(String userId, bool isVerified) async {
    try {
      await _dataSource.verifyUser(userId, isVerified);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapError(e)); }
  }

  @override
  Future<Result<void>> setUserRole(String userId, UserRole role) async {
    try {
      await _dataSource.setUserRole(userId, role.value);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapError(e)); }
  }

  @override
  Future<Result<void>> deleteUserWithContent(String userId) async {
    try {
      await _dataSource.deleteUserWithContent(userId);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapError(e)); }
  }

  @override
  Future<Result<List<Ad>>> getAdsByStatus(AdStatus status, {Object? lastDoc, int limit = 20}) async {
    try {
      final models = await _dataSource.getAdsByStatus(status.value, lastDoc: lastDoc as DocumentSnapshot?, limit: limit);
      return Result.success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return Result.failure(_mapError(e)); }
  }

  @override
  Future<Result<void>> approveAd(String adId) async {
    try {
      await _dataSource.approveAd(adId);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapError(e)); }
  }

  @override
  Future<Result<void>> rejectAd(String adId, String reason) async {
    try {
      await _dataSource.rejectAd(adId, reason);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapError(e)); }
  }

  @override
  Future<Result<void>> deleteAdAdmin(String adId) async {
    try {
      await _dataSource.deleteAdAdmin(adId);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapError(e)); }
  }

  @override
  Future<Result<void>> featureAd(String adId, bool isFeatured) async {
    try {
      await _dataSource.featureAd(adId, isFeatured);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapError(e)); }
  }

  @override
  Future<Result<List<Report>>> getReports({bool? isResolved, Object? lastDoc, int limit = 20}) async {
    try {
      final models = await _dataSource.getReports(isResolved: isResolved, lastDoc: lastDoc as DocumentSnapshot?, limit: limit);
      return Result.success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return Result.failure(_mapError(e)); }
  }

  @override
  Future<Result<void>> resolveReport(String reportId, String adminId, String adminNote) async {
    try {
      await _dataSource.resolveReport(reportId, adminId, adminNote);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapError(e)); }
  }
}
