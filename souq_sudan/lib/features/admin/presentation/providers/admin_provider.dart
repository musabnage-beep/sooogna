import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../ads/domain/entities/ad_entity.dart';
import '../../../ads/presentation/providers/ads_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/admin_repository.dart';

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminRemoteDataSource(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(ref.watch(adminRemoteDataSourceProvider));
});

final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  final result = await ref.watch(adminRepositoryProvider).getDashboardStats();
  return result.when(
    success: (data) => data,
    failure: (message, _) => throw Exception(message),
  );
});

final allUsersProvider =
    FutureProvider.autoDispose<List<AppUser>>((ref) async {
  final result = await ref.watch(adminRepositoryProvider).getAllUsers();
  return result.dataOrNull ?? [];
});

final pendingAdsProvider =
    FutureProvider.autoDispose<List<Ad>>((ref) async {
  final result = await ref
      .watch(adminRepositoryProvider)
      .getAdsByStatus(AdStatus.pending);
  return result.dataOrNull ?? [];
});

final adminAdsByStatusProvider =
    FutureProvider.autoDispose.family<List<Ad>, AdStatus>((ref, status) async {
  final result =
      await ref.watch(adminRepositoryProvider).getAdsByStatus(status);
  return result.dataOrNull ?? [];
});

final reportsProvider =
    FutureProvider.autoDispose.family<List<Report>, bool?>((ref, isResolved) async {
  final result = await ref
      .watch(adminRepositoryProvider)
      .getReports(isResolved: isResolved);
  return result.dataOrNull ?? [];
});

class AdminNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminRepository _repository;
  final Ref _ref;

  AdminNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  void _invalidateAll() {
    _ref.invalidate(dashboardStatsProvider);
    _ref.invalidate(allUsersProvider);
    _ref.invalidate(pendingAdsProvider);
  }

  Future<bool> banUser(String userId, String reason) async {
    state = const AsyncValue.loading();
    final r = await _repository.banUser(userId, reason);
    return r.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _invalidateAll();
        return true;
      },
      failure: (m, _) {
        state = AsyncValue.error(m, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> unbanUser(String userId) async {
    state = const AsyncValue.loading();
    final r = await _repository.unbanUser(userId);
    return r.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _invalidateAll();
        return true;
      },
      failure: (m, _) {
        state = AsyncValue.error(m, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> verifyUser(String userId, bool isVerified) async {
    state = const AsyncValue.loading();
    final r = await _repository.verifyUser(userId, isVerified);
    return r.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _invalidateAll();
        return true;
      },
      failure: (m, _) {
        state = AsyncValue.error(m, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> setUserRole(String userId, UserRole role) async {
    state = const AsyncValue.loading();
    final r = await _repository.setUserRole(userId, role);
    return r.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _invalidateAll();
        return true;
      },
      failure: (m, _) {
        state = AsyncValue.error(m, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> deleteUserWithContent(String userId) async {
    state = const AsyncValue.loading();
    final r = await _repository.deleteUserWithContent(userId);
    return r.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _invalidateAll();
        return true;
      },
      failure: (m, _) {
        state = AsyncValue.error(m, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> approveAd(String adId) async {
    state = const AsyncValue.loading();
    final r = await _repository.approveAd(adId);
    return r.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _invalidateAll();
        return true;
      },
      failure: (m, _) {
        state = AsyncValue.error(m, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> rejectAd(String adId, String reason) async {
    state = const AsyncValue.loading();
    final r = await _repository.rejectAd(adId, reason);
    return r.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _invalidateAll();
        return true;
      },
      failure: (m, _) {
        state = AsyncValue.error(m, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> deleteAdAdmin(String adId) async {
    state = const AsyncValue.loading();
    final r = await _repository.deleteAdAdmin(adId);
    return r.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _invalidateAll();
        return true;
      },
      failure: (m, _) {
        state = AsyncValue.error(m, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> featureAd(String adId, bool isFeatured) async {
    state = const AsyncValue.loading();
    final r = await _repository.featureAd(adId, isFeatured);
    return r.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _invalidateAll();
        return true;
      },
      failure: (m, _) {
        state = AsyncValue.error(m, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> resolveReport(
      String reportId, String adminId, String adminNote) async {
    state = const AsyncValue.loading();
    final r = await _repository.resolveReport(reportId, adminId, adminNote);
    return r.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(reportsProvider);
        _ref.invalidate(dashboardStatsProvider);
        return true;
      },
      failure: (m, _) {
        state = AsyncValue.error(m, StackTrace.current);
        return false;
      },
    );
  }
}

final adminNotifierProvider =
    StateNotifierProvider<AdminNotifier, AsyncValue<void>>((ref) {
  return AdminNotifier(ref.watch(adminRepositoryProvider), ref);
});
