import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/admin_repository.dart';
import '../../../../core/utils/result.dart';

class GetAllUsersUseCase {
  final AdminRepository _repository;
  GetAllUsersUseCase(this._repository);
  Future<Result<List<AppUser>>> call({Object? lastDoc, int limit = 20}) =>
      _repository.getAllUsers(lastDoc: lastDoc, limit: limit);
}
