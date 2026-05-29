import '../entities/report_entity.dart';
import '../repositories/admin_repository.dart';
import '../../../../core/utils/result.dart';

class GetReportsUseCase {
  final AdminRepository _repository;
  GetReportsUseCase(this._repository);
  Future<Result<List<Report>>> call({bool? isResolved, Object? lastDoc, int limit = 20}) =>
      _repository.getReports(isResolved: isResolved, lastDoc: lastDoc, limit: limit);
}
