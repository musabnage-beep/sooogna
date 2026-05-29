import '../entities/review_entity.dart';
import '../repositories/profile_repository.dart';
import '../../../../core/utils/result.dart';

class GetUserReviewsUseCase {
  final ProfileRepository _repository;
  GetUserReviewsUseCase(this._repository);
  Future<Result<List<Review>>> call(String userId) => _repository.getReviewsForUser(userId);
}
