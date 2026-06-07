import '../../../../core/enums/app_enums.dart';

/// A customer-posted request for a service (Feature 2).
class ServiceRequest {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String description;
  final double? budget;
  final String city;
  final String category; // profession id
  final RequestStatus status;
  final int responseCount;
  final DateTime createdAt;

  const ServiceRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.description,
    this.budget,
    required this.city,
    required this.category,
    this.status = RequestStatus.open,
    this.responseCount = 0,
    required this.createdAt,
  });
}

/// A provider's response/offer on a [ServiceRequest].
class ServiceResponse {
  final String id;
  final String providerId;
  final String providerName;
  final String? providerImage;
  final String message;
  final double? price;
  final DateTime createdAt;

  const ServiceResponse({
    required this.id,
    required this.providerId,
    required this.providerName,
    this.providerImage,
    required this.message,
    this.price,
    required this.createdAt,
  });
}
