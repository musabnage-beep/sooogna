import '../../../../core/utils/result.dart';
import '../entities/service_request_entity.dart';

abstract class ServiceRequestsRepository {
  Future<Result<List<ServiceRequest>>> getRequests({
    String? city,
    String? category,
    DateTime? afterCreatedAt,
  });

  Future<Result<ServiceRequest?>> getRequestById(String id);

  Stream<List<ServiceRequest>> watchMyRequests(String userId);

  Future<Result<String>> createRequest(ServiceRequest request);

  Future<Result<void>> setStatus(String requestId, String status);

  Stream<List<ServiceResponse>> watchResponses(String requestId);

  Future<Result<void>> addResponse(String requestId, ServiceResponse response);
}
