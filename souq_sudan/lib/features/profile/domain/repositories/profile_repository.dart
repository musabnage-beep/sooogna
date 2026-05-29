import '../../../auth/domain/entities/user_entity.dart' show AppUser;
import '../entities/review_entity.dart';
import '../../../../core/utils/result.dart';

// Note: imports AppUser from auth domain - acceptable cross-domain dependency
abstract class ProfileRepository {
  Future<Result<AppUser?>> getUserById(String userId);
  Future<Result<void>> updateProfile(String userId, {String? name, String? profileImagePath});
  Future<Result<void>> submitReview(Review review);
  Future<Result<List<Review>>> getReviewsForUser(String userId);
  Future<Result<bool>> hasUserReviewed(String reviewerId, String userId);
  Future<Result<void>> deleteAccount(String userId);
  Future<Result<void>> reportUser(String reporterId, String reporterName, String userId, String reason);
}
