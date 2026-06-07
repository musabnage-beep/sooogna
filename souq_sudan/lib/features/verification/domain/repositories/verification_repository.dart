import '../../../../core/utils/result.dart';
import '../entities/verification_request.dart';

abstract class VerificationRepository {
  Future<Result<void>> submitRequest({
    required String userId,
    required String userName,
    required String requestedStatus,
    String? idImagePath,
  });

  Stream<VerificationRequest?> watchMyRequest(String userId);

  Stream<List<VerificationRequest>> watchPending();

  Future<Result<void>> approve({
    required String userId,
    required String grantedStatus,
    String? adminNote,
  });

  Future<Result<void>> reject({required String userId, String? adminNote});
}
