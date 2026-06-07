import '../../../ads/domain/entities/ad_entity.dart';
import '../../../../core/utils/result.dart';
import '../entities/store_entity.dart';

abstract class StoresRepository {
  Future<Result<Store?>> getStoreById(String storeId);
  Stream<Store?> watchMyStore(String ownerId);
  Future<Result<List<Ad>>> getStoreProducts(String storeId,
      {DateTime? afterCreatedAt});
  Future<Result<void>> upsertStore(Store store,
      {String? newLogoPath, String? newBannerPath});
}
