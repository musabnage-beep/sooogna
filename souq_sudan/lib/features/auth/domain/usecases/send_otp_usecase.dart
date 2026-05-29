import '../repositories/auth_repository.dart';
import '../../../../core/utils/result.dart';

class SendOtpUseCase {
  final AuthRepository _repository;
  SendOtpUseCase(this._repository);

  Future<Result<String>> call(String phoneNumber) {
    return _repository.sendOtp(phoneNumber);
  }
}
