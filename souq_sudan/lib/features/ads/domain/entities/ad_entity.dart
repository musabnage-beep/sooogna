import '../../../../core/enums/app_enums.dart';
export '../../../../core/enums/app_enums.dart' show OwnerType;

class AdsPage {
  final List<Ad> ads;
  final Object? lastDoc;
  const AdsPage({required this.ads, this.lastDoc});
}

class Ad {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final List<String> images;
  final String userId;
  final String? userName;
  final String? userPhone;
  final String location;
  final String? city;
  final OwnerType ownerType;
  final String? adState;
  final bool isFeatured;
  final bool featuredRequested;
  final AdStatus status;
  final String? rejectionReason;
  final int viewCount;
  final int favoriteCount;
  final double userRating;
  final DateTime createdAt;
  final DateTime? bumpedAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> attributes;

  const Ad({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.images,
    required this.userId,
    this.userName,
    this.userPhone,
    required this.location,
    this.city,
    this.ownerType = OwnerType.owner,
    this.adState,
    this.isFeatured = false,
    this.featuredRequested = false,
    this.status = AdStatus.pending,
    this.rejectionReason,
    this.viewCount = 0,
    this.favoriteCount = 0,
    this.userRating = 0.0,
    required this.createdAt,
    this.bumpedAt,
    this.updatedAt,
    this.expiresAt,
    this.attributes = const {},
  });

  Ad copyWith({
    String? id, String? title, String? description, double? price,
    String? category, List<String>? images, String? userId,
    String? userName, String? userPhone, String? location,
    String? city, OwnerType? ownerType,
    String? adState, bool? isFeatured, bool? featuredRequested,
    AdStatus? status, String? rejectionReason,
    int? viewCount, int? favoriteCount, double? userRating,
    DateTime? createdAt, DateTime? bumpedAt,
    DateTime? updatedAt, DateTime? expiresAt,
    Map<String, dynamic>? attributes,
  }) {
    return Ad(
      id: id ?? this.id, title: title ?? this.title,
      description: description ?? this.description, price: price ?? this.price,
      category: category ?? this.category, images: images ?? this.images,
      userId: userId ?? this.userId, userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone, location: location ?? this.location,
      city: city ?? this.city, ownerType: ownerType ?? this.ownerType,
      adState: adState ?? this.adState,
      isFeatured: isFeatured ?? this.isFeatured,
      featuredRequested: featuredRequested ?? this.featuredRequested,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      viewCount: viewCount ?? this.viewCount, favoriteCount: favoriteCount ?? this.favoriteCount,
      userRating: userRating ?? this.userRating,
      createdAt: createdAt ?? this.createdAt,
      bumpedAt: bumpedAt ?? this.bumpedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      attributes: attributes ?? this.attributes,
    );
  }
}
