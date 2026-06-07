import '../../../../core/enums/app_enums.dart';

/// A professional service provider profile (Feature 1).
/// Doc id == userId, so each user can own at most one service profile.
class ServiceProfile {
  final String userId;
  final String name;
  final String? profileImage;
  final String profession; // profession id (see AppConstants.serviceProfessions)
  final String description;
  final String city;
  final List<String> portfolioImages;
  final String? whatsapp;
  final String? phone;
  final double rating;
  final int ratingCount;
  final VerifiedStatus verifiedStatus;
  final bool isActive;
  final DateTime createdAt;

  const ServiceProfile({
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
    this.verifiedStatus = VerifiedStatus.unverified,
    this.isActive = true,
    required this.createdAt,
  });

  ServiceProfile copyWith({
    String? name,
    String? profileImage,
    String? profession,
    String? description,
    String? city,
    List<String>? portfolioImages,
    String? whatsapp,
    String? phone,
    bool? isActive,
  }) {
    return ServiceProfile(
      userId: userId,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      profession: profession ?? this.profession,
      description: description ?? this.description,
      city: city ?? this.city,
      portfolioImages: portfolioImages ?? this.portfolioImages,
      whatsapp: whatsapp ?? this.whatsapp,
      phone: phone ?? this.phone,
      rating: rating,
      ratingCount: ratingCount,
      verifiedStatus: verifiedStatus,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
