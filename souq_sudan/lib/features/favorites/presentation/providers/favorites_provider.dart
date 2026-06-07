import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ads/domain/entities/ad_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/favorites_remote_datasource.dart';
import '../../data/repositories/favorites_repository_impl.dart';
import '../../domain/entities/favorite_ad.dart';
import '../../domain/repositories/favorites_repository.dart';

final favoritesRemoteDataSourceProvider =
    Provider<FavoritesRemoteDataSource>((ref) {
  return FavoritesRemoteDataSource(firestore: ref.watch(firestoreProvider));
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepositoryImpl(ref.watch(favoritesRemoteDataSourceProvider));
});

/// Live list of the signed-in user's saved ads (newest first).
final savedAdsProvider = StreamProvider<List<FavoriteAd>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(const []);
  return ref.watch(favoritesRepositoryProvider).watchFavorites(user.id);
});

/// Lightweight set of saved ad IDs for fast toggle-state lookups on cards.
final favoriteIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(const {});
  return ref.watch(favoritesRepositoryProvider).watchFavoriteIds(user.id);
});

class FavoritesNotifier extends StateNotifier<bool> {
  final FavoritesRepository _repository;
  final Ref _ref;

  FavoritesNotifier(this._repository, this._ref) : super(false);

  /// Toggles saved state for [ad]. Returns true if it is now saved.
  Future<bool?> toggle(Ad ad, bool currentlySaved) async {
    if (state) return null; // re-entrancy guard
    final user = _ref.read(currentUserProvider).value;
    if (user == null) return null;
    state = true;
    final result = currentlySaved
        ? await _repository.removeFavorite(user.id, ad.id)
        : await _repository.addFavorite(user.id, ad);
    state = false;
    return result.isSuccess ? !currentlySaved : null;
  }

  /// Removes a saved ad by id (used by the Saved tab where only the id is
  /// known). Guards against re-entrant taps so rapid clicks can't queue
  /// duplicate Firestore writes. Returns true on success.
  Future<bool> remove(String adId) async {
    if (state) return false; // re-entrancy guard
    final user = _ref.read(currentUserProvider).value;
    if (user == null) return false;
    state = true;
    final result = await _repository.removeFavorite(user.id, adId);
    state = false;
    return result.isSuccess;
  }
}

final favoritesNotifierProvider =
    StateNotifierProvider<FavoritesNotifier, bool>((ref) {
  return FavoritesNotifier(ref.watch(favoritesRepositoryProvider), ref);
});
