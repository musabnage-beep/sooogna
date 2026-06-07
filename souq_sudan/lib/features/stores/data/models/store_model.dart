import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/helpers.dart';
import '../../domain/entities/store_entity.dart';

class StoreModel {
  final String storeId;
  final String ownerId;
  final String name;
  final String? logo;
  final String? banner;
  final String description;
  final String? whatsapp;
  final String? phone;
  final String city;
  final double rating;
  final int ratingCount;
  final int productCount;
  final List<String> searchKeywords;
  final Timestamp createdAt;

  const StoreModel({
    required this.storeId,
    required this.ownerId,
    required this.name,
    this.logo,
    this.banner,
    this.description = '',
    this.whatsapp,
    this.phone,
    required this.city,
    this.rating = 0,
    this.ratingCount = 0,
    this.productCount = 0,
    this.searchKeywords = const [],
    required this.createdAt,
  });

  factory StoreModel.fromMap(Map<String, dynamic> map, String id) {
    final contact = (map['contactInfo'] as Map<String, dynamic>?) ?? const {};
    return StoreModel(
      storeId: id,
      ownerId: (map['ownerId'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      logo: map['logo'] as String?,
      banner: map['banner'] as String?,
      description: (map['description'] as String?) ?? '',
      whatsapp: contact['whatsapp'] as String?,
      phone: contact['phone'] as String?,
      city: (map['city'] as String?) ?? '',
      rating: ((map['rating'] as num?) ?? 0).toDouble(),
      ratingCount: (map['ratingCount'] as int?) ?? 0,
      productCount: (map['productCount'] as int?) ?? 0,
      searchKeywords: List<String>.from(map['searchKeywords'] as List? ?? []),
      createdAt: (map['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  factory StoreModel.fromDocument(DocumentSnapshot doc) {
    return StoreModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'logo': logo,
      'banner': banner,
      'description': description,
      'contactInfo': {'whatsapp': whatsapp, 'phone': phone},
      'city': city,
      'rating': rating,
      'ratingCount': ratingCount,
      'productCount': productCount,
      'searchKeywords': searchKeywords,
      'createdAt': createdAt,
    };
  }

  Store toEntity() {
    return Store(
      storeId: storeId,
      ownerId: ownerId,
      name: name,
      logo: logo,
      banner: banner,
      description: description,
      whatsapp: whatsapp,
      phone: phone,
      city: city,
      rating: rating,
      ratingCount: ratingCount,
      productCount: productCount,
      createdAt: createdAt.toDate(),
    );
  }

  static StoreModel fromEntity(Store store) {
    final keywords = <String>{
      ...Helpers.extractSearchKeywords(store.name),
      if (store.city.isNotEmpty) store.city.toLowerCase(),
    }.toList();
    return StoreModel(
      storeId: store.storeId,
      ownerId: store.ownerId,
      name: store.name,
      logo: store.logo,
      banner: store.banner,
      description: store.description,
      whatsapp: store.whatsapp,
      phone: store.phone,
      city: store.city,
      rating: store.rating,
      ratingCount: store.ratingCount,
      productCount: store.productCount,
      searchKeywords: keywords,
      createdAt: Timestamp.fromDate(store.createdAt),
    );
  }
}
