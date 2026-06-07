import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/service_request_entity.dart';
import '../../domain/repositories/service_requests_repository.dart';
import '../datasources/service_requests_remote_datasource.dart';
import '../models/service_request_model.dart';

class ServiceRequestsRepositoryImpl implements ServiceRequestsRepository {
  final ServiceRequestsRemoteDataSource _dataSource;

  ServiceRequestsRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<ServiceRequest>>> getRequests({
    String? city,
    String? category,
    DateTime? afterCreatedAt,
  }) async {
    try {
      final models = await _dataSource.getRequests(
        city: city,
        category: category,
        afterCreatedAt:
            afterCreatedAt != null ? Timestamp.fromDate(afterCreatedAt) : null,
      );
      return Result.success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return const Result.failure('تعذر تحميل الطلبات');
    }
  }

  @override
  Future<Result<ServiceRequest?>> getRequestById(String id) async {
    try {
      final model = await _dataSource.getRequestById(id);
      return Result.success(model?.toEntity());
    } catch (e) {
      return const Result.failure('تعذر تحميل الطلب');
    }
  }

  @override
  Stream<List<ServiceRequest>> watchMyRequests(String userId) {
    return _dataSource
        .watchMyRequests(userId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Result<String>> createRequest(ServiceRequest request) async {
    try {
      final id = await _dataSource.createRequest(ServiceRequestModel(
        id: request.id,
        userId: request.userId,
        userName: request.userName,
        title: request.title,
        description: request.description,
        budget: request.budget,
        city: request.city,
        category: request.category,
        status: request.status.value,
        responseCount: request.responseCount,
        createdAt: Timestamp.fromDate(request.createdAt),
      ));
      return Result.success(id);
    } catch (e) {
      return const Result.failure('تعذر إنشاء الطلب');
    }
  }

  @override
  Future<Result<void>> setStatus(String requestId, String status) async {
    try {
      await _dataSource.setStatus(requestId, status);
      return const Result.success(null);
    } catch (e) {
      return const Result.failure('تعذر تحديث حالة الطلب');
    }
  }

  @override
  Stream<List<ServiceResponse>> watchResponses(String requestId) {
    return _dataSource
        .watchResponses(requestId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Result<void>> addResponse(
      String requestId, ServiceResponse response) async {
    try {
      await _dataSource.addResponse(
        requestId,
        ServiceResponseModel(
          id: response.id,
          providerId: response.providerId,
          providerName: response.providerName,
          providerImage: response.providerImage,
          message: response.message,
          price: response.price,
          createdAt: Timestamp.fromDate(response.createdAt),
        ),
      );
      return const Result.success(null);
    } catch (e) {
      return const Result.failure('تعذر إرسال العرض');
    }
  }
}
