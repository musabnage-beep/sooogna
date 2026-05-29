import '../repositories/auth_repository.dart';
import '../../../../core/utils/result.dart';

class VerifyOtpUseCase {
  final AuthRepository _repository;
  VerifyOtpUseCase(this._repository);

  Future<Result<bool>> call(String verificationId, String otp) {
    return _repository.verifyOtp(verificationId, otp);
  }
}
