import '../../../../core/enums/app_enums.dart';

class AppUser {
  final String id;
  final String name;
  final String phone;
  final String? city;
  final String? gender;
  final String? profileImage;
  final bool isVerified;
  final VerifiedStatus verifiedStatus;
  final double rating;
  final int ratingCount;
  final int profileVisits;
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
    this.city,
    this.gender,
    this.profileImage,
    this.isVerified = false,
    this.verifiedStatus = VerifiedStatus.unverified,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.profileVisits = 0,
    this.role = UserRole.user,
    this.isBanned = false,
    this.banReason,
    required this.createdAt,
    this.lastActiveAt,
    this.fcmToken,
  });

  bool get isAdmin => role == UserRole.admin;

  AppUser copyWith({
    String? id, String? name, String? phone, String? profileImage,
    String? city, String? gender,
    bool? isVerified, VerifiedStatus? verifiedStatus,
    double? rating, int? ratingCount, int? profileVisits,
    UserRole? role, bool? isBanned, String? banReason,
    DateTime? createdAt, DateTime? lastActiveAt, String? fcmToken,
  }) {
    return AppUser(
      id: id ?? this.id, name: name ?? this.name, phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      city: city ?? this.city, gender: gender ?? this.gender,
      isVerified: isVerified ?? this.isVerified,
      verifiedStatus: verifiedStatus ?? this.verifiedStatus,
      rating: rating ?? this.rating, ratingCount: ratingCount ?? this.ratingCount,
      profileVisits: profileVisits ?? this.profileVisits,
      role: role ?? this.role, isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
