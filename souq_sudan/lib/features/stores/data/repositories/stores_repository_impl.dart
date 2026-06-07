import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../ads/domain/entities/ad_entity.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/store_entity.dart';
import '../../domain/repositories/stores_repository.dart';
import '../datasources/stores_remote_datasource.dart';
import '../models/store_model.dart';

class StoresRepositoryImpl implements StoresRepository {
  final StoresRemoteDataSource _dataSource;

  StoresRepositoryImpl(this._dataSource);

  @override
  Future<Result<Store?>> getStoreById(String storeId) async {
    try {
      final model = await _dataSource.getStoreById(storeId);
      return Result.success(model?.toEntity());
    } catch (e) {
      return const Result.failure('تعذر تحميل المتجر');
    }
  }

  @override
  Stream<Store?> watchMyStore(String ownerId) {
    return _dataSource.watchMyStore(ownerId).map((m) => m?.toEntity());
  }

  @override
  Future<Result<List<Ad>>> getStoreProducts(String storeId,
      {DateTime? afterCreatedAt}) async {
    try {
      final models = await _dataSource.getStoreProducts(
        storeId,
        afterCreatedAt:
            afterCreatedAt != null ? Timestamp.fromDate(afterCreatedAt) : null,
      );
      return Result.success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return const Result.failure('تعذر تحميل منتجات المتجر');
    }
  }

  @override
  Future<Result<void>> upsertStore(Store store,
      {String? newLogoPath, String? newBannerPath}) async {
    try {
      await _dataSource.upsertStore(
        StoreModel.fromEntity(store),
        newLogoPath: newLogoPath,
        newBannerPath: newBannerPath,
      );
      return const Result.success(null);
    } catch (e) {
      return const Result.failure('تعذر حفظ المتجر');
    }
  }
}
