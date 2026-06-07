import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/repositories/services_repository.dart';
import '../datasources/services_remote_datasource.dart';
import '../models/service_model.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  final ServicesRemoteDataSource _dataSource;

  ServicesRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<ServiceProfile>>> getServices({
    String? profession,
    String? city,
    double? afterRating,
    DateTime? afterCreatedAt,
  }) async {
    try {
      final models = await _dataSource.getServices(
        profession: profession,
        city: city,
        afterRating: afterRating,
        afterCreatedAt:
            afterCreatedAt != null ? Timestamp.fromDate(afterCreatedAt) : null,
      );
      return Result.success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return const Result.failure('تعذر تحميل مزودي الخدمات');
    }
  }

  @override
  Future<Result<List<ServiceProfile>>> searchServices(String query) async {
    try {
      final models = await _dataSource.searchServices(query);
      return Result.success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return const Result.failure('تعذر البحث عن الخدمات');
    }
  }

  @override
  Future<Result<ServiceProfile?>> getServiceById(String userId) async {
    try {
      final model = await _dataSource.getServiceById(userId);
      return Result.success(model?.toEntity());
    } catch (e) {
      return const Result.failure('تعذر تحميل ملف مزود الخدمة');
    }
  }

  @override
  Stream<ServiceProfile?> watchMyService(String userId) {
    return _dataSource.watchMyService(userId).map((m) => m?.toEntity());
  }

  @override
  Future<Result<void>> upsertService(
    ServiceProfile service, {
    String? newProfileImagePath,
    List<String> newPortfolioPaths = const [],
  }) async {
    try {
      await _dataSource.upsertService(
        ServiceModel.fromEntity(service),
        newProfileImagePath: newProfileImagePath,
        newPortfolioPaths: newPortfolioPaths,
      );
      return const Result.success(null);
    } catch (e) {
      return const Result.failure('تعذر حفظ ملف الخدمة');
    }
  }

  @override
  Future<Result<void>> setActive(String userId, bool isActive) async {
    try {
      await _dataSource.setActive(userId, isActive);
      return const Result.success(null);
    } catch (e) {
      return const Result.failure('تعذر تحديث حالة الخدمة');
    }
  }
}
