import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../core/enums/app_enums.dart';

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? profileImage;
  final bool isVerified;
  final double rating;
  final int ratingCount;
  final String role;
  final bool isBanned;
  final String? banReason;
  final Timestamp createdAt;
  final Timestamp? lastActiveAt;
  final String? fcmToken;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.profileImage,
    this.isVerified = false,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.role = 'user',
    this.isBanned = false,
    this.banReason,
    required this.createdAt,
    this.lastActiveAt,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: (map['name'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      profileImage: map['profileImage'] as String?,
      isVerified: (map['isVerified'] as bool?) ?? false,
      rating: ((map['rating'] as num?) ?? 0).toDouble(),
      ratingCount: (map['ratingCount'] as int?) ?? 0,
      role: (map['role'] as String?) ?? 'user',
      isBanned: (map['isBanned'] as bool?) ?? false,
      banReason: map['banReason'] as String?,
      createdAt: (map['createdAt'] as Timestamp?) ?? Timestamp.now(),
      lastActiveAt: map['lastActiveAt'] as Timestamp?,
      fcmToken: map['fcmToken'] as String?,
    );
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'profileImage': profileImage,
      'isVerified': isVerified,
      'rating': rating,
      'ratingCount': ratingCount,
      'role': role,
      'isBanned': isBanned,
      'banReason': banReason,
      'createdAt': createdAt,
      'lastActiveAt': lastActiveAt,
      'fcmToken': fcmToken,
    };
  }

  AppUser toEntity() {
    return AppUser(
      id: id,
      name: name,
      phone: phone,
      profileImage: profileImage,
      isVerified: isVerified,
      rating: rating,
      ratingCount: ratingCount,
      role: UserRoleExtension.fromString(role),
      isBanned: isBanned,
      banReason: banReason,
      createdAt: createdAt.toDate(),
      lastActiveAt: lastActiveAt?.toDate(),
      fcmToken: fcmToken,
    );
  }

  static UserModel fromEntity(AppUser user) {
    return UserModel(
      id: user.id,
      name: user.name,
      phone: user.phone,
      profileImage: user.profileImage,
      isVerified: user.isVerified,
      rating: user.rating,
      ratingCount: user.ratingCount,
      role: user.role.value,
      isBanned: user.isBanned,
      banReason: user.banReason,
      createdAt: Timestamp.fromDate(user.createdAt),
      lastActiveAt: user.lastActiveAt != null ? Timestamp.fromDate(user.lastActiveAt!) : null,
      fcmToken: user.fcmToken,
    );
  }
}
