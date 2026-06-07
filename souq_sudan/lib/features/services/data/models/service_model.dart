import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/utils/helpers.dart';
import '../../domain/entities/service_entity.dart';

class ServiceModel {
  final String userId;
  final String name;
  final String? profileImage;
  final String profession;
  final String description;
  final String city;
  final List<String> portfolioImages;
  final String? whatsapp;
  final String? phone;
  final double rating;
  final int ratingCount;
  final String verifiedStatus;
  final List<String> searchKeywords;
  final bool isActive;
  final Timestamp createdAt;

  const ServiceModel({
    required this.userId,
    required this.name,
    this.profileImage,
    required this.profession,
    required this.description,
    required this.city,
    this.portfolioImages = const [],
    this.whatsapp,
    this.phone,
    this.rating = 0,
    this.ratingCount = 0,
    this.verifiedStatus = 'unverified',
    this.searchKeywords = const [],
    this.isActive = true,
    required this.createdAt,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map, String id) {
    final contact = (map['contactOptions'] as Map<String, dynamic>?) ?? const {};
    return ServiceModel(
      userId: (map['userId'] as String?) ?? id,
      name: (map['name'] as String?) ?? '',
      profileImage: map['profileImage'] as String?,
      profession: (map['profession'] as String?) ?? 'other',
      description: (map['description'] as String?) ?? '',
      city: (map['city'] as String?) ?? '',
      portfolioImages: List<String>.from(map['portfolioImages'] as List? ?? []),
      whatsapp: contact['whatsapp'] as String?,
      phone: contact['phone'] as String?,
      rating: ((map['rating'] as num?) ?? 0).toDouble(),
      ratingCount: (map['ratingCount'] as int?) ?? 0,
      verifiedStatus: (map['verifiedStatus'] as String?) ?? 'unverified',
      searchKeywords: List<String>.from(map['searchKeywords'] as List? ?? []),
      isActive: (map['isActive'] as bool?) ?? true,
      createdAt: (map['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  factory ServiceModel.fromDocument(DocumentSnapshot doc) {
    return ServiceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'profileImage': profileImage,
      'profession': profession,
      'description': description,
      'city': city,
      'portfolioImages': portfolioImages,
      'contactOptions': {'whatsapp': whatsapp, 'phone': phone},
      'rating': rating,
      'ratingCount': ratingCount,
      'verifiedStatus': verifiedStatus,
      'searchKeywords': searchKeywords,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  ServiceProfile toEntity() {
    return ServiceProfile(
      userId: userId,
      name: name,
      profileImage: profileImage,
      profession: profession,
      description: description,
      city: city,
      portfolioImages: portfolioImages,
      whatsapp: whatsapp,
      phone: phone,
      rating: rating,
      ratingCount: ratingCount,
      verifiedStatus: VerifiedStatusExtension.fromString(verifiedStatus),
      isActive: isActive,
      createdAt: createdAt.toDate(),
    );
  }

  static ServiceModel fromEntity(ServiceProfile s) {
    final keywords = <String>{
      ...Helpers.extractSearchKeywords(s.name),
      ...Helpers.extractSearchKeywords(s.description),
      s.profession,
      s.city,
    }.where((w) => w.isNotEmpty).toList();
    return ServiceModel(
      userId: s.userId,
      name: s.name,
      profileImage: s.profileImage,
      profession: s.profession,
      description: s.description,
      city: s.city,
      portfolioImages: s.portfolioImages,
      whatsapp: s.whatsapp,
      phone: s.phone,
      rating: s.rating,
      ratingCount: s.ratingCount,
      verifiedStatus: s.verifiedStatus.value,
      searchKeywords: keywords,
      isActive: s.isActive,
      createdAt: Timestamp.fromDate(s.createdAt),
    );
  }
}
