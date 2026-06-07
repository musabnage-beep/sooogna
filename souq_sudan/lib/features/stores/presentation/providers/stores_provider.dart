import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../ads/domain/entities/ad_entity.dart';
import '../../../ads/presentation/providers/ads_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/stores_remote_datasource.dart';
import '../../data/repositories/stores_repository_impl.dart';
import '../../domain/entities/store_entity.dart';
import '../../domain/repositories/stores_repository.dart';

final storesRemoteDataSourceProvider = Provider<StoresRemoteDataSource>((ref) {
  return StoresRemoteDataSource(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

final storesRepositoryProvider = Provider<StoresRepository>((ref) {
  return StoresRepositoryImpl(ref.watch(storesRemoteDataSourceProvider));
});

/// The signed-in user's own store (null if none yet).
final myStoreProvider = StreamProvider<Store?>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(storesRepositoryProvider).watchMyStore(user.id);
});

final storeByIdProvider =
    FutureProvider.family<Store?, String>((ref, storeId) async {
  final result = await ref.watch(storesRepositoryProvider).getStoreById(storeId);
  return result.dataOrNull;
});

class StoreProductsState {
  final List<Ad> products;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const StoreProductsState({
    this.products = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  StoreProductsState copyWith({
    List<Ad>? products,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return StoreProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class StoreProductsNotifier extends StateNotifier<StoreProductsState> {
  final StoresRepository _repository;
  final String storeId;

  StoreProductsNotifier(this._repository, this.storeId)
      : super(const StoreProductsState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, products: [], hasMore: true);
    final result = await _repository.getStoreProducts(storeId);
    result.when(
      success: (list) => state = state.copyWith(
        isLoading: false,
        products: list,
        hasMore: list.length >= AppConstants.storeProductsPageSize,
      ),
      failure: (msg, _) => state = state.copyWith(isLoading: false, error: msg),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.products.isEmpty) return;
    state = state.copyWith(isLoading: true);
    final result = await _repository.getStoreProducts(
      storeId,
      afterCreatedAt: state.products.last.createdAt,
    );
    result.when(
      success: (list) => state = state.copyWith(
        isLoading: false,
        products: [...state.products, ...list],
        hasMore: list.length >= AppConstants.storeProductsPageSize,
      ),
      failure: (msg, _) => state = state.copyWith(isLoading: false, error: msg),
    );
  }

  Future<void> refresh() => loadInitial();
}

final storeProductsProvider = StateNotifierProvider.family<StoreProductsNotifier,
    StoreProductsState, String>((ref, storeId) {
  return StoreProductsNotifier(ref.watch(storesRepositoryProvider), storeId);
});

/// Create/update of the caller's own store.
class StoreFormNotifier extends StateNotifier<AsyncValue<void>> {
  final StoresRepository _repository;

  StoreFormNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<bool> save(
    Store store, {
    String? newLogoPath,
    String? newBannerPath,
  }) async {
    if (state.isLoading) return false;
    state = const AsyncValue.loading();
    final result = await _repository.upsertStore(
      store,
      newLogoPath: newLogoPath,
      newBannerPath: newBannerPath,
    );
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        return true;
      },
      failure: (msg, _) {
        state = AsyncValue.error(msg, StackTrace.current);
        return false;
      },
    );
  }
}

final storeFormProvider =
    StateNotifierProvider<StoreFormNotifier, AsyncValue<void>>((ref) {
  return StoreFormNotifier(ref.watch(storesRepositoryProvider));
});
