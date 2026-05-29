import '../entities/dashboard_stats_entity.dart';
import '../repositories/admin_repository.dart';
import '../../../../core/utils/result.dart';

class GetDashboardStatsUseCase {
  final AdminRepository _repository;
  GetDashboardStatsUseCase(this._repository);
  Future<Result<DashboardStats>> call() => _repository.getDashboardStats();
}
