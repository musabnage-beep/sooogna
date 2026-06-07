import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/enums/app_enums.dart';
import '../../domain/entities/service_request_entity.dart';

class ServiceRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String description;
  final double? budget;
  final String city;
  final String category;
  final String status;
  final int responseCount;
  final Timestamp createdAt;

  const ServiceRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.description,
    this.budget,
    required this.city,
    required this.category,
    this.status = 'open',
    this.responseCount = 0,
    required this.createdAt,
  });

  factory ServiceRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return ServiceRequestModel(
      id: id,
      userId: (map['userId'] as String?) ?? '',
      userName: (map['userName'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      budget: (map['budget'] as num?)?.toDouble(),
      city: (map['city'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'other',
      status: (map['status'] as String?) ?? 'open',
      responseCount: (map['responseCount'] as int?) ?? 0,
      createdAt: (map['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  factory ServiceRequestModel.fromDocument(DocumentSnapshot doc) {
    return ServiceRequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'title': title,
      'description': description,
      'budget': budget,
      'city': city,
      'category': category,
      'status': status,
      'responseCount': responseCount,
      'createdAt': createdAt,
    };
  }

  ServiceRequest toEntity() {
    return ServiceRequest(
      id: id,
      userId: userId,
      userName: userName,
      title: title,
      description: description,
      budget: budget,
      city: city,
      category: category,
      status: RequestStatusExtension.fromString(status),
      responseCount: responseCount,
      createdAt: createdAt.toDate(),
    );
  }
}

class ServiceResponseModel {
  final String id;
  final String providerId;
  final String providerName;
  final String? providerImage;
  final String message;
  final double? price;
  final Timestamp createdAt;

  const ServiceResponseModel({
    required this.id,
    required this.providerId,
    required this.providerName,
    this.providerImage,
    required this.message,
    this.price,
    required this.createdAt,
  });

  factory ServiceResponseModel.fromMap(Map<String, dynamic> map, String id) {
    return ServiceResponseModel(
      id: id,
      providerId: (map['providerId'] as String?) ?? '',
      providerName: (map['providerName'] as String?) ?? '',
      providerImage: map['providerImage'] as String?,
      message: (map['message'] as String?) ?? '',
      price: (map['price'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  factory ServiceResponseModel.fromDocument(DocumentSnapshot doc) {
    return ServiceResponseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'providerName': providerName,
      'providerImage': providerImage,
      'message': message,
      'price': price,
      'createdAt': createdAt,
    };
  }

  ServiceResponse toEntity() {
    return ServiceResponse(
      id: id,
      providerId: providerId,
      providerName: providerName,
      providerImage: providerImage,
      message: message,
      price: price,
      createdAt: createdAt.toDate(),
    );
  }
}
