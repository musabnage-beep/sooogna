import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../ads/domain/entities/ad_entity.dart';
import '../../domain/entities/favorite_ad.dart';

class FavoriteAdModel {
  final String adId;
  final String title;
  final double price;
  final String? image;
  final String city;
  final Timestamp savedAt;

  const FavoriteAdModel({
    required this.adId,
    required this.title,
    required this.price,
    this.image,
    this.city = '',
    required this.savedAt,
  });

  factory FavoriteAdModel.fromMap(Map<String, dynamic> map, String id) {
    return FavoriteAdModel(
      adId: (map['adId'] as String?) ?? id,
      title: (map['title'] as String?) ?? '',
      price: ((map['price'] as num?) ?? 0).toDouble(),
      image: map['image'] as String?,
      city: (map['city'] as String?) ?? '',
      savedAt: (map['savedAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  factory FavoriteAdModel.fromDocument(DocumentSnapshot doc) {
    return FavoriteAdModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'adId': adId,
      'title': title,
      'price': price,
      'image': image,
      'city': city,
      'savedAt': savedAt,
    };
  }

  FavoriteAd toEntity() {
    return FavoriteAd(
      adId: adId,
      title: title,
      price: price,
      image: image,
      city: city,
      savedAt: savedAt.toDate(),
    );
  }

  static FavoriteAdModel fromAd(Ad ad) {
    return FavoriteAdModel(
      adId: ad.id,
      title: ad.title,
      price: ad.price,
      image: ad.images.isNotEmpty ? ad.images.first : null,
      city: ad.city ?? '',
      savedAt: Timestamp.now(),
    );
  }
}
