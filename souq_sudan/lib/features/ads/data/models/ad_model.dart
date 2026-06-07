import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/ad_entity.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/utils/helpers.dart';

class AdModel {
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
  final String ownerType;
  final String? adState;
  final bool isFeatured;
  final bool featuredRequested;
  final String status;
  final String? rejectionReason;
  final int viewCount;
  final int favoriteCount;
  final double userRating;
  final List<String> searchKeywords;
  final Timestamp createdAt;
  final Timestamp? bumpedAt;
  final Timestamp? updatedAt;
  final Timestamp? expiresAt;

  const AdModel({
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
    this.ownerType = 'owner',
    this.adState,
    this.isFeatured = false,
    this.featuredRequested = false,
    this.status = 'pending',
    this.rejectionReason,
    this.viewCount = 0,
    this.favoriteCount = 0,
    this.userRating = 0.0,
    this.searchKeywords = const [],
    required this.createdAt,
    this.bumpedAt,
    this.updatedAt,
    this.expiresAt,
  });

  factory AdModel.fromMap(Map<String, dynamic> map, String id) {
    return AdModel(
      id: id,
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      price: ((map['price'] as num?) ?? 0).toDouble(),
      category: (map['category'] as String?) ?? '',
      images: List<String>.from(map['images'] as List? ?? []),
      userId: (map['userId'] as String?) ?? '',
      userName: map['userName'] as String?,
      userPhone: map['userPhone'] as String?,
      location: (map['location'] as String?) ?? '',
      city: map['city'] as String?,
      ownerType: (map['ownerType'] as String?) ?? 'owner',
      adState: map['adState'] as String?,
      isFeatured: (map['isFeatured'] as bool?) ?? false,
      featuredRequested: (map['featuredRequested'] as bool?) ?? false,
      status: (map['status'] as String?) ?? 'pending',
      rejectionReason: map['rejectionReason'] as String?,
      viewCount: (map['viewCount'] as int?) ?? 0,
      favoriteCount: (map['favoriteCount'] as int?) ?? 0,
      userRating: ((map['userRating'] as num?) ?? 0).toDouble(),
      searchKeywords: List<String>.from(map['searchKeywords'] as List? ?? []),
      createdAt: (map['createdAt'] as Timestamp?) ?? Timestamp.now(),
      bumpedAt: map['bumpedAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
      expiresAt: map['expiresAt'] as Timestamp?,
    );
  }

  factory AdModel.fromDocument(DocumentSnapshot doc) {
    return AdModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'images': images,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'location': location,
      'city': city,
      'ownerType': ownerType,
      'adState': adState,
      'isFeatured': isFeatured,
      'featuredRequested': featuredRequested,
      'status': status,
      'rejectionReason': rejectionReason,
      'viewCount': viewCount,
      'favoriteCount': favoriteCount,
      'userRating': userRating,
      'searchKeywords': searchKeywords,
      'createdAt': createdAt,
      'bumpedAt': bumpedAt,
      'updatedAt': updatedAt,
      'expiresAt': expiresAt,
    };
  }

  Ad toEntity() {
    return Ad(
      id: id,
      title: title,
      description: description,
      price: price,
      category: category,
      images: images,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      location: location,
      city: city,
      ownerType: OwnerTypeExtension.fromString(ownerType),
      adState: adState,
      isFeatured: isFeatured,
      featuredRequested: featuredRequested,
      status: AdStatusExtension.fromString(status),
      rejectionReason: rejectionReason,
      viewCount: viewCount,
      favoriteCount: favoriteCount,
      userRating: userRating,
      createdAt: createdAt.toDate(),
      bumpedAt: bumpedAt?.toDate(),
      updatedAt: updatedAt?.toDate(),
      expiresAt: expiresAt?.toDate(),
    );
  }

  static AdModel fromEntity(Ad ad) {
    final keywords = Helpers.extractSearchKeywords(ad.title);
    final extractedState = ad.adState ??
        (ad.location.contains(' - ') ? ad.location.split(' - ').first : null);
    return AdModel(
      id: ad.id,
      title: ad.title,
      description: ad.description,
      price: ad.price,
      category: ad.category,
      images: ad.images,
      userId: ad.userId,
      userName: ad.userName,
      userPhone: ad.userPhone,
      location: ad.location,
      city: ad.city,
      ownerType: ad.ownerType.value,
      adState: extractedState,
      isFeatured: ad.isFeatured,
      featuredRequested: ad.featuredRequested,
      status: ad.status.value,
      rejectionReason: ad.rejectionReason,
      viewCount: ad.viewCount,
      favoriteCount: ad.favoriteCount,
      userRating: ad.userRating,
      searchKeywords: keywords,
      createdAt: Timestamp.fromDate(ad.createdAt),
      bumpedAt: ad.bumpedAt != null ? Timestamp.fromDate(ad.bumpedAt!) : null,
      updatedAt: ad.updatedAt != null ? Timestamp.fromDate(ad.updatedAt!) : null,
      expiresAt: ad.expiresAt != null ? Timestamp.fromDate(ad.expiresAt!) : null,
    );
  }
}
