import '../../../auth/domain/entities/user_entity.dart' show AppUser;
import '../repositories/profile_repository.dart';
import '../../../../core/utils/result.dart';

class GetUserProfileUseCase {
  final ProfileRepository _repository;
  GetUserProfileUseCase(this._repository);
  Future<Result<AppUser?>> call(String userId) => _repository.getUserById(userId);
}
