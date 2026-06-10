import '../entities/user_entity.dart';
import '../../../../core/utils/result.dart';

abstract class AuthRepository {
  Future<Result<String>> sendOtp(String phoneNumber);
  Future<Result<bool>> verifyOtp(String verificationId, String otp);
  Future<Result<bool>> userExists(String uid);
  Future<Result<AppUser>> createUser(String uid, String name, String phone, {String? city, String? gender});
  Future<Result<AppUser?>> getCurrentUser();
  Stream<AppUser?> watchUser(String uid);
  Future<Result<void>> logout();
  Future<Result<void>> updateFcmToken(String userId, String? token);
  String? get currentUserId;
}
