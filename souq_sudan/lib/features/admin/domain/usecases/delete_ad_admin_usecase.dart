import '../repositories/admin_repository.dart';
import '../../../../core/utils/result.dart';

class DeleteAdAdminUseCase {
  final AdminRepository _repository;
  DeleteAdAdminUseCase(this._repository);
  Future<Result<void>> call(String adId) => _repository.deleteAdAdmin(adId);
}
