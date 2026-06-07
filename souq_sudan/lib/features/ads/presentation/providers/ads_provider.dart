import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/ads_remote_datasource.dart';
import '../../data/repositories/ads_repository_impl.dart';
import '../../domain/entities/ad_entity.dart';
import '../../domain/repositories/ads_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Firebase Storage provider
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);

// Data source
final adsRemoteDataSourceProvider = Provider<AdsRemoteDataSource>((ref) {
  return AdsRemoteDataSource(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

// Repository
final adsRepositoryProvider = Provider<AdsRepository>((ref) {
  return AdsRepositoryImpl(ref.watch(adsRemoteDataSourceProvider));
});

// Ad detail
final adDetailProvider = FutureProvider.family<Ad?, String>((ref, adId) async {
  final result = await ref.watch(adsRepositoryProvider).getAdById(adId);
  return result.dataOrNull;
});

// User ads
final userAdsProvider = FutureProvider.family<List<Ad>, String>((ref, userId) async {
  final result = await ref.watch(adsRepositoryProvider).getAdsByUser(userId);
  return result.dataOrNull ?? [];
});

// Featured ads
final featuredAdsProvider = FutureProvider<List<Ad>>((ref) async {
  final result = await ref.watch(adsRepositoryProvider).getFeaturedAds();
  return result.dataOrNull ?? [];
});

// Home ads state
class HomeAdsState {
  final List<Ad> ads;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final Object? lastDoc;
  final String? selectedState;

  const HomeAdsState({
    this.ads = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.lastDoc,
    this.selectedState,
  });

  HomeAdsState copyWith({
    List<Ad>? ads,
    bool? isLoading,
    bool? hasMore,
    String? error,
    Object? lastDoc,
    String? selectedState,
    bool clearSelectedState = false,
  }) {
    return HomeAdsState(
      ads: ads ?? this.ads,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      lastDoc: lastDoc ?? this.lastDoc,
      selectedState: clearSelectedState ? null : (selectedState ?? this.selectedState),
    );
  }
}

class HomeAdsNotifier extends StateNotifier<HomeAdsState> {
  final AdsRepository _repository;

  HomeAdsNotifier(this._repository) : super(const HomeAdsState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = HomeAdsState(isLoading: true, selectedState: state.selectedState);
    final result = await _repository.getAds(limit: 20, stateFilter: state.selectedState);
    result.when(
      success: (ads) => state = state.copyWith(isLoading: false, ads: ads, hasMore: ads.length >= 20),
      failure: (msg, _) => state = state.copyWith(isLoading: false, error: msg),
    );
  }

  Future<void> loadMore(Object? lastDoc) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    final result = await _repository.getAds(lastDoc: lastDoc, limit: 20, stateFilter: state.selectedState);
    result.when(
      success: (newAds) => state = state.copyWith(
        isLoading: false,
        ads: [...state.ads, ...newAds],
        hasMore: newAds.length >= 20,
        lastDoc: lastDoc,
      ),
      failure: (msg, _) => state = state.copyWith(isLoading: false, error: msg),
    );
  }

  Future<void> setStateFilter(String? selectedState) async {
    state = HomeAdsState(isLoading: true, selectedState: selectedState);
    final result = await _repository.getAds(limit: 20, stateFilter: selectedState);
    result.when(
      success: (ads) => state = state.copyWith(isLoading: false, ads: ads, hasMore: ads.length >= 20),
      failure: (msg, _) => state = state.copyWith(isLoading: false, error: msg),
    );
  }

  Future<void> refresh() => loadInitial();
}

final homeAdsProvider = StateNotifierProvider<HomeAdsNotifier, HomeAdsState>((ref) {
  return HomeAdsNotifier(ref.watch(adsRepositoryProvider));
});

// Category ads state
class CategoryAdsNotifier extends StateNotifier<HomeAdsState> {
  final AdsRepository _repository;
  final String categoryId;

  CategoryAdsNotifier(this._repository, this.categoryId) : super(const HomeAdsState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, ads: [], lastDoc: null, hasMore: true);
    final result = await _repository.getAdsByCategory(categoryId, limit: 20);
    result.when(
      success: (ads) => state = state.copyWith(isLoading: false, ads: ads, hasMore: ads.length >= 20),
      failure: (msg, _) => state = state.copyWith(isLoading: false, error: msg),
    );
  }

  Future<void> loadMore(Object? lastDoc) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    final result = await _repository.getAdsByCategory(categoryId, lastDoc: lastDoc, limit: 20);
    result.when(
      success: (newAds) => state = state.copyWith(
        isLoading: false,
        ads: [...state.ads, ...newAds],
        hasMore: newAds.length >= 20,
        lastDoc: lastDoc,
      ),
      failure: (msg, _) => state = state.copyWith(isLoading: false, error: msg),
    );
  }

  Future<void> refresh() => loadInitial();
}

final categoryAdsProvider = StateNotifierProvider.family<CategoryAdsNotifier, HomeAdsState, String>((ref, categoryId) {
  return CategoryAdsNotifier(ref.watch(adsRepositoryProvider), categoryId);
});

// Search state
class SearchState {
  final List<Ad> results;
  final bool isLoading;
  final String? error;

  const SearchState({this.results = const [], this.isLoading = false, this.error});

  SearchState copyWith({List<Ad>? results, bool? isLoading, String? error}) {
    return SearchState(results: results ?? this.results, isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final AdsRepository _repository;

  SearchNotifier(this._repository) : super(const SearchState());

  Future<void> search(String query, {String? category, String? location, double? minPrice, double? maxPrice, String? sortBy}) async {
    if (query.trim().isEmpty && category == null && location == null) {
      state = const SearchState();
      return;
    }
    state = state.copyWith(isLoading: true);
    final result = await _repository.searchAds(query, category: category, location: location, minPrice: minPrice, maxPrice: maxPrice, sortBy: sortBy);
    result.when(
      success: (ads) => state = state.copyWith(isLoading: false, results: ads),
      failure: (msg, _) => state = state.copyWith(isLoading: false, error: msg),
    );
  }

  void clear() => state = const SearchState();
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.watch(adsRepositoryProvider));
});

// Create ad state
class CreateAdState {
  final bool isLoading;
  final String? statusMessage;
  final String? error;
  final bool success;

  const CreateAdState({
    this.isLoading = false,
    this.statusMessage,
    this.error,
    this.success = false,
  });

  CreateAdState copyWith({bool? isLoading, String? statusMessage, String? error, bool? success}) {
    return CreateAdState(
      isLoading: isLoading ?? this.isLoading,
      statusMessage: statusMessage,
      error: error,
      success: success ?? this.success,
    );
  }
}

class CreateAdNotifier extends StateNotifier<CreateAdState> {
  final AdsRepository _repository;

  CreateAdNotifier(this._repository) : super(const CreateAdState());

  Future<String?> createAd(Ad ad, List<String> localImagePaths) async {
    state = const CreateAdState(isLoading: true, statusMessage: 'جاري رفع الصور...');

    final countResult = await _repository.getUserAdCountToday(ad.userId);
    final count = countResult.dataOrNull ?? 0;
    if (count >= 10) {
      state = const CreateAdState(error: 'لقد تجاوزت الحد المسموح من الإعلانات اليومية (10 إعلانات)');
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastPost = prefs.getInt('last_ad_post_time');
    if (lastPost != null) {
      final diff = DateTime.now().millisecondsSinceEpoch - lastPost;
      if (diff < 2 * 60 * 1000) {
        final remaining = ((2 * 60 * 1000 - diff) / 1000).ceil();
        state = CreateAdState(error: 'يرجى الانتظار $remaining ثانية بين كل إعلان');
        return null;
      }
    }

    state = const CreateAdState(isLoading: true, statusMessage: 'جاري رفع الصور...');
    final result = await _repository.createAd(ad, localImagePaths);

    return result.when(
      success: (adId) async {
        await prefs.setInt('last_ad_post_time', DateTime.now().millisecondsSinceEpoch);
        state = const CreateAdState(success: true, statusMessage: 'تم نشر الإعلان بنجاح!');
        return adId;
      },
      failure: (msg, _) {
        state = CreateAdState(error: msg);
        return null;
      },
    );
  }

  Future<bool> updateAd(Ad ad, List<String> newLocalImagePaths, List<String> removedImageUrls) async {
    state = const CreateAdState(isLoading: true, statusMessage: 'جاري تحديث الإعلان...');
    final result = await _repository.updateAd(ad, newLocalImagePaths, removedImageUrls);
    return result.when(
      success: (_) {
        state = const CreateAdState(success: true);
        return true;
      },
      failure: (msg, _) {
        state = CreateAdState(error: msg);
        return false;
      },
    );
  }

  void reset() => state = const CreateAdState();
}

final createAdProvider = StateNotifierProvider<CreateAdNotifier, CreateAdState>((ref) {
  return CreateAdNotifier(ref.watch(adsRepositoryProvider));
});
