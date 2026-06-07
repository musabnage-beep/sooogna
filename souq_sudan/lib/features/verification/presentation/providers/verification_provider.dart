import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ads/presentation/providers/ads_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/verification_remote_datasource.dart';
import '../../data/repositories/verification_repository_impl.dart';
import '../../domain/entities/verification_request.dart';
import '../../domain/repositories/verification_repository.dart';

final verificationRemoteDataSourceProvider =
    Provider<VerificationRemoteDataSource>((ref) {
  return VerificationRemoteDataSource(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepositoryImpl(ref.watch(verificationRemoteDataSourceProvider));
});

/// The current user's verification request (null if none submitted).
final myVerificationRequestProvider =
    StreamProvider<VerificationRequest?>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(verificationRepositoryProvider).watchMyRequest(user.id);
});

/// Admin: stream of pending verification requests.
final pendingVerificationsProvider =
    StreamProvider<List<VerificationRequest>>((ref) {
  return ref.watch(verificationRepositoryProvider).watchPending();
});

class VerificationNotifier extends StateNotifier<AsyncValue<void>> {
  final VerificationRepository _repository;

  VerificationNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<bool> submit({
    required String userId,
    required String userName,
    required String requestedStatus,
    String? idImagePath,
  }) async {
    if (state.isLoading) return false;
    state = const AsyncValue.loading();
    final result = await _repository.submitRequest(
      userId: userId,
      userName: userName,
      requestedStatus: requestedStatus,
      idImagePath: idImagePath,
    );
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        return true;
      },
      failure: (message, _) {
        state = AsyncValue.error(message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> approve({
    required String userId,
    required String grantedStatus,
    String? adminNote,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.approve(
      userId: userId,
      grantedStatus: grantedStatus,
      adminNote: adminNote,
    );
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        return true;
      },
      failure: (message, _) {
        state = AsyncValue.error(message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> reject({required String userId, String? adminNote}) async {
    state = const AsyncValue.loading();
    final result = await _repository.reject(userId: userId, adminNote: adminNote);
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        return true;
      },
      failure: (message, _) {
        state = AsyncValue.error(message, StackTrace.current);
        return false;
      },
    );
  }
}

final verificationNotifierProvider =
    StateNotifierProvider<VerificationNotifier, AsyncValue<void>>((ref) {
  return VerificationNotifier(ref.watch(verificationRepositoryProvider));
});
