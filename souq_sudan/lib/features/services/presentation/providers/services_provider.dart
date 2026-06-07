import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../ads/presentation/providers/ads_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/services_remote_datasource.dart';
import '../../data/repositories/services_repository_impl.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/repositories/services_repository.dart';

final servicesRemoteDataSourceProvider =
    Provider<ServicesRemoteDataSource>((ref) {
  return ServicesRemoteDataSource(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  return ServicesRepositoryImpl(ref.watch(servicesRemoteDataSourceProvider));
});

/// The signed-in user's own service profile (null if none yet).
final myServiceProvider = StreamProvider<ServiceProfile?>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(servicesRepositoryProvider).watchMyService(user.id);
});

final serviceByIdProvider =
    FutureProvider.family<ServiceProfile?, String>((ref, userId) async {
  final result = await ref.watch(servicesRepositoryProvider).getServiceById(userId);
  return result.dataOrNull;
});

/// Active filters for the services browse list.
class ServicesFilter {
  final String? profession;
  final String? city;
  const ServicesFilter({this.profession, this.city});

  ServicesFilter copyWith({String? profession, String? city, bool clear = false}) {
    if (clear) return const ServicesFilter();
    return ServicesFilter(
      profession: profession ?? this.profession,
      city: city ?? this.city,
    );
  }
}

class ServicesListState {
  final List<ServiceProfile> services;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final ServicesFilter filter;

  const ServicesListState({
    this.services = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.filter = const ServicesFilter(),
  });

  ServicesListState copyWith({
    List<ServiceProfile>? services,
    bool? isLoading,
    bool? hasMore,
    String? error,
    ServicesFilter? filter,
  }) {
    return ServicesListState(
      services: services ?? this.services,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      filter: filter ?? this.filter,
    );
  }
}

class ServicesListNotifier extends StateNotifier<ServicesListState> {
  final ServicesRepository _repository;

  ServicesListNotifier(this._repository) : super(const ServicesListState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, services: [], hasMore: true);
    final result = await _repository.getServices(
      profession: state.filter.profession,
      city: state.filter.city,
    );
    result.when(
      success: (list) => state = state.copyWith(
        isLoading: false,
        services: list,
        hasMore: list.length >= AppConstants.servicesPageSize,
      ),
      failure: (msg, _) => state = state.copyWith(isLoading: false, error: msg),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.services.isEmpty) return;
    state = state.copyWith(isLoading: true);
    final last = state.services.last;
    final result = await _repository.getServices(
      profession: state.filter.profession,
      city: state.filter.city,
      afterRating: last.rating,
      afterCreatedAt: last.createdAt,
    );
    result.when(
      success: (list) => state = state.copyWith(
        isLoading: false,
        services: [...state.services, ...list],
        hasMore: list.length >= AppConstants.servicesPageSize,
      ),
      failure: (msg, _) => state = state.copyWith(isLoading: false, error: msg),
    );
  }

  Future<void> applyFilter(ServicesFilter filter) async {
    state = state.copyWith(filter: filter);
    await loadInitial();
  }

  Future<void> refresh() => loadInitial();
}

final servicesListProvider =
    StateNotifierProvider<ServicesListNotifier, ServicesListState>((ref) {
  return ServicesListNotifier(ref.watch(servicesRepositoryProvider));
});

/// One-shot search results for the services browse search field.
class ServicesSearchNotifier extends StateNotifier<AsyncValue<List<ServiceProfile>>> {
  final ServicesRepository _repository;

  ServicesSearchNotifier(this._repository) : super(const AsyncValue.data([]));

  Future<void> search(String query) async {
    if (query.trim().length < 2) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    final result = await _repository.searchServices(query);
    state = result.when(
      success: AsyncValue.data,
      failure: (msg, _) => AsyncValue.error(msg, StackTrace.current),
    );
  }

  void clear() => state = const AsyncValue.data([]);
}

final servicesSearchProvider = StateNotifierProvider<ServicesSearchNotifier,
    AsyncValue<List<ServiceProfile>>>((ref) {
  return ServicesSearchNotifier(ref.watch(servicesRepositoryProvider));
});

/// Create/update of the caller's own service profile.
class ServiceFormNotifier extends StateNotifier<AsyncValue<void>> {
  final ServicesRepository _repository;

  ServiceFormNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<bool> save(
    ServiceProfile service, {
    String? newProfileImagePath,
    List<String> newPortfolioPaths = const [],
  }) async {
    if (state.isLoading) return false;
    state = const AsyncValue.loading();
    final result = await _repository.upsertService(
      service,
      newProfileImagePath: newProfileImagePath,
      newPortfolioPaths: newPortfolioPaths,
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

final serviceFormProvider =
    StateNotifierProvider<ServiceFormNotifier, AsyncValue<void>>((ref) {
  return ServiceFormNotifier(ref.watch(servicesRepositoryProvider));
});
