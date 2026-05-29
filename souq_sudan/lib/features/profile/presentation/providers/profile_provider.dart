import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_entity.dart' show AppUser;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ads/presentation/providers/ads_provider.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/profile_repository.dart';

// Data source
final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

// Repository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider));
});

// User profile
final userByIdProvider = FutureProvider.family<AppUser?, String>((ref, userId) async {
  final result = await ref.watch(profileRepositoryProvider).getUserById(userId);
  return result.dataOrNull;
});

// Reviews for a user
final userReviewsProvider = FutureProvider.family<List<Review>, String>((ref, userId) async {
  final result = await ref.watch(profileRepositoryProvider).getReviewsForUser(userId);
  return result.dataOrNull ?? [];
});

// Has this reviewer already reviewed the user?
final hasUserReviewedProvider =
    FutureProvider.family<bool, ({String reviewerId, String userId})>((ref, args) async {
  final result = await ref
      .watch(profileRepositoryProvider)
      .hasUserReviewed(args.reviewerId, args.userId);
  return result.dataOrNull ?? false;
});

class ProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final ProfileRepository _repository;
  final Ref _ref;

  ProfileNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<bool> updateProfile({
    required String userId,
    String? name,
    String? profileImagePath,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateProfile(
      userId,
      name: name,
      profileImagePath: profileImagePath,
    );
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(userByIdProvider(userId));
        return true;
      },
      failure: (message, _) {
        state = AsyncValue.error(message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> submitReview(Review review) async {
    state = const AsyncValue.loading();
    final result = await _repository.submitReview(review);
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(userReviewsProvider(review.userId));
        _ref.invalidate(userByIdProvider(review.userId));
        _ref.invalidate(
          hasUserReviewedProvider((reviewerId: review.reviewerId, userId: review.userId)),
        );
        return true;
      },
      failure: (message, _) {
        state = AsyncValue.error(message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> deleteAccount(String userId) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteAccount(userId);
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

  Future<bool> reportUser({
    required String reporterId,
    required String reporterName,
    required String userId,
    required String reason,
  }) async {
    state = const AsyncValue.loading();
    final result =
        await _repository.reportUser(reporterId, reporterName, userId, reason);
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

  void clearError() {
    state = const AsyncValue.data(null);
  }
}

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<void>>((ref) {
  return ProfileNotifier(ref.watch(profileRepositoryProvider), ref);
});
