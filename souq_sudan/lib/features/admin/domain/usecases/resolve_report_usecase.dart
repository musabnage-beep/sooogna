import '../repositories/admin_repository.dart';
import '../../../../core/utils/result.dart';

class ResolveReportUseCase {
  final AdminRepository _repository;
  ResolveReportUseCase(this._repository);
  Future<Result<void>> call(String reportId, String adminId, String adminNote) =>
      _repository.resolveReport(reportId, adminId, adminNote);
}
