import '../../../../core/enums/app_enums.dart';

class AppUser {
  final String id;
  final String name;
  final String phone;
  final String? profileImage;
  final bool isVerified;
  final double rating;
  final int ratingCount;
  final UserRole role;
  final bool isBanned;
  final String? banReason;
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final String? fcmToken;

  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    this.profileImage,
    this.isVerified = false,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.role = UserRole.user,
    this.isBanned = false,
    this.banReason,
    required this.createdAt,
    this.lastActiveAt,
    this.fcmToken,
  });

  bool get isAdmin => role == UserRole.admin;

  AppUser copyWith({
    String? id,
    String? name,
    String? phone,
    String? profileImage,
    bool? isVerified,
    double? rating,
    int? ratingCount,
    UserRole? role,
    bool? isBanned,
    String? banReason,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    String? fcmToken,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      role: role ?? this.role,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
