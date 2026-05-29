import '../../../ads/domain/entities/ad_entity.dart';
import '../repositories/admin_repository.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/utils/result.dart';

class GetPendingAdsUseCase {
  final AdminRepository _repository;
  GetPendingAdsUseCase(this._repository);
  Future<Result<List<Ad>>> call({Object? lastDoc, int limit = 20}) =>
      _repository.getAdsByStatus(AdStatus.pending, lastDoc: lastDoc, limit: limit);
}
