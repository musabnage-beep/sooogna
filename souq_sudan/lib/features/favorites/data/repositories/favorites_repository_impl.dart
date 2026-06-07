import '../../../../core/utils/result.dart';
import '../../../ads/domain/entities/ad_entity.dart';
import '../../domain/entities/favorite_ad.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_remote_datasource.dart';
import '../models/favorite_ad_model.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesRemoteDataSource _dataSource;

  FavoritesRepositoryImpl(this._dataSource);

  @override
  Stream<List<FavoriteAd>> watchFavorites(String uid) {
    return _dataSource
        .watchFavorites(uid)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Stream<Set<String>> watchFavoriteIds(String uid) =>
      _dataSource.watchFavoriteIds(uid);

  @override
  Future<Result<void>> addFavorite(String uid, Ad ad) async {
    try {
      await _dataSource.addFavorite(uid, FavoriteAdModel.fromAd(ad));
      return const Result.success(null);
    } catch (e) {
      return const Result.failure('تعذر حفظ الإعلان');
    }
  }

  @override
  Future<Result<void>> removeFavorite(String uid, String adId) async {
    try {
      await _dataSource.removeFavorite(uid, adId);
      return const Result.success(null);
    } catch (e) {
      return const Result.failure('تعذر إزالة الإعلان');
    }
  }
}
