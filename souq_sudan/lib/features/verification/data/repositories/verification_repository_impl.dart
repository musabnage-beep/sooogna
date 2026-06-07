import '../../../../core/utils/result.dart';
import '../../domain/entities/verification_request.dart';
import '../../domain/repositories/verification_repository.dart';
import '../datasources/verification_remote_datasource.dart';

class VerificationRepositoryImpl implements VerificationRepository {
  final VerificationRemoteDataSource _ds;

  VerificationRepositoryImpl(this._ds);

  @override
  Future<Result<void>> submitRequest({
    required String userId,
    required String userName,
    required String requestedStatus,
    String? idImagePath,
  }) async {
    try {
      await _ds.submitRequest(
        userId: userId,
        userName: userName,
        requestedStatus: requestedStatus,
        idImagePath: idImagePath,
      );
      return const Result.success(null);
    } catch (e) {
      return Result.failure('تعذر إرسال طلب التوثيق', exception: e is Exception ? e : null);
    }
  }

  @override
  Stream<VerificationRequest?> watchMyRequest(String userId) {
    return _ds.watchMyRequest(userId).map((m) => m?.toEntity());
  }

  @override
  Stream<List<VerificationRequest>> watchPending() {
    return _ds.watchPending().map((list) => list.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Result<void>> approve({
    required String userId,
    required String grantedStatus,
    String? adminNote,
  }) async {
    try {
      await _ds.approve(userId: userId, grantedStatus: grantedStatus, adminNote: adminNote);
      return const Result.success(null);
    } catch (e) {
      return Result.failure('تعذر قبول الطلب', exception: e is Exception ? e : null);
    }
  }

  @override
  Future<Result<void>> reject({required String userId, String? adminNote}) async {
    try {
      await _ds.reject(userId: userId, adminNote: adminNote);
      return const Result.success(null);
    } catch (e) {
      return Result.failure('تعذر رفض الطلب', exception: e is Exception ? e : null);
    }
  }
}
