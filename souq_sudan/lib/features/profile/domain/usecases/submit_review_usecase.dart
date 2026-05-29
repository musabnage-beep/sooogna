import '../entities/review_entity.dart';
import '../repositories/profile_repository.dart';
import '../../../../core/utils/result.dart';

class SubmitReviewUseCase {
  final ProfileRepository _repository;
  SubmitReviewUseCase(this._repository);
  Future<Result<void>> call(Review review) => _repository.submitReview(review);
}
