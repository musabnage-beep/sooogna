import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../auth/domain/entities/user_entity.dart' show AppUser;
import 'rating_widget.dart';

class ProfileHeader extends StatelessWidget {
  final AppUser user;
  final bool maskPhone;

  const ProfileHeader({
    super.key,
    required this.user,
    this.maskPhone = true,
  });

  @override
  Widget build(BuildContext context) {
    final phoneText = maskPhone ? Validators.maskPhone(user.phone) : user.phone;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomLeft,
            children: [
              ClipOval(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: CachedImageWidget(
                    imageUrl: user.profileImage,
                    width: 100,
                    height: 100,
                    placeholder: Container(
                      width: 100,
                      height: 100,
                      color: Colors.white,
                      alignment: Alignment.center,
                      child: Text(
                        Helpers.getInitials(user.name),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (user.isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: AppColors.verifiedBlue,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (user.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                phoneText,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                textTheme: Theme.of(context).textTheme.apply(
                      bodyColor: Colors.white,
                      displayColor: Colors.white,
                    ),
              ),
              child: RatingWidget(
                rating: user.rating,
                reviewCount: user.ratingCount,
                color: AppColors.gold,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'عضو ${Helpers.formatMemberSince(user.createdAt)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
