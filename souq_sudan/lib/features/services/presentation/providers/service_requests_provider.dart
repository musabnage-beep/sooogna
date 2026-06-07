import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/service_requests_remote_datasource.dart';
import '../../data/repositories/service_requests_repository_impl.dart';
import '../../domain/entities/service_request_entity.dart';
import '../../domain/repositories/service_requests_repository.dart';

final serviceRequestsRemoteDataSourceProvider =
    Provider<ServiceRequestsRemoteDataSource>((ref) {
  return ServiceRequestsRemoteDataSource(firestore: ref.watch(firestoreProvider));
});

final serviceRequestsRepositoryProvider =
    Provider<ServiceRequestsRepository>((ref) {
  return ServiceRequestsRepositoryImpl(
      ref.watch(serviceRequestsRemoteDataSourceProvider));
});

final requestByIdProvider =
    FutureProvider.family<ServiceRequest?, String>((ref, id) async {
  final result = await ref.watch(serviceRequestsRepositoryProvider).getRequestById(id);
  return result.dataOrNull;
});

final requestResponsesProvider =
    StreamProvider.family<List<ServiceResponse>, String>((ref, requestId) {
  return ref.watch(serviceRequestsRepositoryProvider).watchResponses(requestId);
});

final myRequestsProvider = StreamProvider<List<ServiceRequest>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(const []);
  return ref.watch(serviceRequestsRepositoryProvider).watchMyRequests(user.id);
});

class RequestsFilter {
  final String? city;
  final String? category;
  const RequestsFilter({this.city, this.category});
}

class RequestsListState {
  final List<ServiceRequest> requests;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final RequestsFilter filter;

  const RequestsListState({
    this.requests = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.filter = const RequestsFilter(),
  });

  RequestsListState copyWith({
    List<ServiceRequest>? requests,
    bool? isLoading,
    bool? hasMore,
    String? error,
    RequestsFilter? filter,
  }) {
    return RequestsListState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      filter: filter ?? this.filter,
    );
  }
}

class RequestsListNotifier extends StateNotifier<RequestsListState> {
  final ServiceRequestsRepository _repository;

  RequestsListNotifier(this._repository) : super(const RequestsListState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, requests: [], hasMore: true);
    final result = await _repository.getRequests(
      city: state.filter.city,
      category: state.filter.category,
    );
    result.when(
      success: (list) => state = state.copyWith(
        isLoading: false,
        requests: list,
        hasMore: list.length >= AppConstants.requestsPageSize,
      ),
      failure: (msg, _) => state = state.copyWith(isLoading: false, error: msg),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.requests.isEmpty) return;
    state = state.copyWith(isLoading: true);
    final result = await _repository.getRequests(
      city: state.filter.city,
      category: state.filter.category,
      afterCreatedAt: state.requests.last.createdAt,
    );
    result.when(
      success: (list) => state = state.copyWith(
        isLoading: false,
        requests: [...state.requests, ...list],
        hasMore: list.length >= AppConstants.requestsPageSize,
      ),
      failure: (msg, _) => state = state.copyWith(isLoading: false, error: msg),
    );
  }

  Future<void> applyFilter(RequestsFilter filter) async {
    state = state.copyWith(filter: filter);
    await loadInitial();
  }

  Future<void> refresh() => loadInitial();
}

final requestsListProvider =
    StateNotifierProvider<RequestsListNotifier, RequestsListState>((ref) {
  return RequestsListNotifier(ref.watch(serviceRequestsRepositoryProvider));
});

/// Create-request + respond actions share one busy notifier per screen use.
class RequestActionNotifier extends StateNotifier<AsyncValue<void>> {
  final ServiceRequestsRepository _repository;

  RequestActionNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<String?> create(ServiceRequest request) async {
    if (state.isLoading) return null;
    state = const AsyncValue.loading();
    final result = await _repository.createRequest(request);
    return result.when(
      success: (id) {
        state = const AsyncValue.data(null);
        return id;
      },
      failure: (msg, _) {
        state = AsyncValue.error(msg, StackTrace.current);
        return null;
      },
    );
  }

  Future<bool> respond(String requestId, ServiceResponse response) async {
    if (state.isLoading) return false;
    state = const AsyncValue.loading();
    final result = await _repository.addResponse(requestId, response);
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

  Future<bool> setStatus(String requestId, String status) async {
    final result = await _repository.setStatus(requestId, status);
    return result.isSuccess;
  }
}

final requestActionProvider =
    StateNotifierProvider<RequestActionNotifier, AsyncValue<void>>((ref) {
  return RequestActionNotifier(ref.watch(serviceRequestsRepositoryProvider));
});
