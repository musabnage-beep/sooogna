import '../entities/report_entity.dart';
import '../entities/dashboard_stats_entity.dart';
import '../../../ads/domain/entities/ad_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/utils/result.dart';

abstract class AdminRepository {
  Future<Result<DashboardStats>> getDashboardStats();
  Future<Result<List<AppUser>>> getAllUsers({Object? lastDoc, int limit = 20});
  Future<Result<void>> banUser(String userId, String reason);
  Future<Result<void>> unbanUser(String userId);
  Future<Result<void>> verifyUser(String userId, bool isVerified);
  Future<Result<void>> setUserRole(String userId, UserRole role);
  Future<Result<void>> deleteUserWithContent(String userId);
  Future<Result<List<Ad>>> getAdsByStatus(AdStatus status, {Object? lastDoc, int limit = 20});
  Future<Result<void>> approveAd(String adId);
  Future<Result<void>> rejectAd(String adId, String reason);
  Future<Result<void>> deleteAdAdmin(String adId);
  Future<Result<void>> featureAd(String adId, bool isFeatured);
  Future<Result<List<Report>>> getReports({bool? isResolved, Object? lastDoc, int limit = 20});
  Future<Result<void>> resolveReport(String reportId, String adminId, String adminNote);
}
