import '../../../../core/utils/result.dart';
import '../entities/service_entity.dart';

abstract class ServicesRepository {
  Future<Result<List<ServiceProfile>>> getServices({
    String? profession,
    String? city,
    double? afterRating,
    DateTime? afterCreatedAt,
  });

  Future<Result<List<ServiceProfile>>> searchServices(String query);

  Future<Result<ServiceProfile?>> getServiceById(String userId);

  Stream<ServiceProfile?> watchMyService(String userId);

  Future<Result<void>> upsertService(
    ServiceProfile service, {
    String? newProfileImagePath,
    List<String> newPortfolioPaths,
  });

  Future<Result<void>> setActive(String userId, bool isActive);
}
