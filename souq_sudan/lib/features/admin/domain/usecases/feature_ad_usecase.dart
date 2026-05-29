import '../repositories/admin_repository.dart';
import '../../../../core/utils/result.dart';

class FeatureAdUseCase {
  final AdminRepository _repository;
  FeatureAdUseCase(this._repository);
  Future<Result<void>> call(String adId, bool isFeatured) => _repository.featureAd(adId, isFeatured);
}
