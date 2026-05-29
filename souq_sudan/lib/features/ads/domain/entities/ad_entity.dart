import '../../../../core/enums/app_enums.dart';

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
  final bool isFeatured;
  final AdStatus status;
  final String? rejectionReason;
  final int viewCount;
  final int favoriteCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

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
    this.isFeatured = false,
    this.status = AdStatus.pending,
    this.rejectionReason,
    this.viewCount = 0,
    this.favoriteCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.expiresAt,
  });

  Ad copyWith({
    String? id, String? title, String? description, double? price,
    String? category, List<String>? images, String? userId,
    String? userName, String? userPhone, String? location,
    bool? isFeatured, AdStatus? status, String? rejectionReason,
    int? viewCount, int? favoriteCount, DateTime? createdAt,
    DateTime? updatedAt, DateTime? expiresAt,
  }) {
    return Ad(
      id: id ?? this.id, title: title ?? this.title,
      description: description ?? this.description, price: price ?? this.price,
      category: category ?? this.category, images: images ?? this.images,
      userId: userId ?? this.userId, userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone, location: location ?? this.location,
      isFeatured: isFeatured ?? this.isFeatured, status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      viewCount: viewCount ?? this.viewCount, favoriteCount: favoriteCount ?? this.favoriteCount,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
