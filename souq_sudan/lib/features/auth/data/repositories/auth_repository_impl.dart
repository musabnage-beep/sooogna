import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../../../core/utils/result.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  String? get currentUserId => _dataSource.currentUserId;

  @override
  Future<Result<String>> sendOtp(String phoneNumber) async {
    try {
      final verificationId = await _dataSource.sendOtp(phoneNumber);
      return Result.success(verificationId);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_mapAuthError(e));
    } on SocketException {
      return const Result.failure('لا يوجد اتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى');
    } catch (e) {
      return Result.failure('حدث خطأ أثناء إرسال رمز التحقق: ${e.toString()}');
    }
  }

  @override
  Future<Result<bool>> verifyOtp(String verificationId, String otp) async {
    try {
      final success = await _dataSource.verifyOtp(verificationId, otp);
      return Result.success(success);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_mapAuthError(e));
    } on SocketException {
      return const Result.failure('لا يوجد اتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى');
    } catch (e) {
      return const Result.failure('حدث خطأ أثناء التحقق من الرمز');
    }
  }

  @override
  Future<Result<bool>> userExists(String uid) async {
    try {
      final exists = await _dataSource.userExists(uid);
      return Result.success(exists);
    } catch (e) {
      return const Result.failure('خطأ في التحقق من المستخدم');
    }
  }

  @override
  Future<Result<AppUser>> createUser(String uid, String name, String phone) async {
    try {
      final model = await _dataSource.createUser(uid, name, phone);
      return Result.success(model.toEntity());
    } catch (e) {
      return Result.failure('خطأ في إنشاء الحساب: ${e.toString()}');
    }
  }

  @override
  Future<Result<AppUser?>> getCurrentUser() async {
    try {
      final uid = _dataSource.currentUserId;
      if (uid == null) return const Result.success(null);
      final model = await _dataSource.getUserById(uid);
      return Result.success(model?.toEntity());
    } catch (e) {
      return const Result.failure('خطأ في جلب بيانات المستخدم');
    }
  }

  @override
  Stream<AppUser?> watchUser(String uid) {
    return _dataSource.watchUser(uid).map((model) => model?.toEntity());
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _dataSource.logout();
      return const Result.success(null);
    } catch (e) {
      return const Result.failure('خطأ في تسجيل الخروج');
    }
  }

  @override
  Future<Result<void>> updateFcmToken(String userId, String? token) async {
    try {
      await _dataSource.updateFcmToken(userId, token);
      return const Result.success(null);
    } catch (e) {
      return const Result.success(null);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'رقم الهاتف غير صحيح';
      case 'too-many-requests':
        return 'تم تجاوز عدد المحاولات المسموحة، حاول مرة أخرى لاحقاً';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح';
      case 'session-expired':
        return 'انتهت صلاحية رمز التحقق، يرجى طلب رمز جديد';
      case 'network-request-failed':
        return 'لا يوجد اتصال بالإنترنت';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      default:
        return 'حدث خطأ في المصادقة (${e.code})';
    }
  }
}
