import '../repositories/profile_repository.dart';
import '../../../../core/utils/result.dart';

class UpdateProfileUseCase {
  final ProfileRepository _repository;
  UpdateProfileUseCase(this._repository);
  Future<Result<void>> call(String userId, {String? name, String? profileImagePath}) {
    return _repository.updateProfile(userId, name: name, profileImagePath: profileImagePath);
  }
}
