import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../auth/domain/entities/user_entity.dart';

class UserManagementTile extends StatelessWidget {
  final AppUser user;
  final VoidCallback onTap;

  const UserManagementTile({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: ClipOval(
        child: SizedBox(
          width: 44,
          height: 44,
          child: CachedImageWidget(
            imageUrl: user.profileImage,
            width: 44,
            height: 44,
            placeholder: Container(
              color: AppColors.background,
              alignment: Alignment.center,
              child: Text(
                Helpers.getInitials(user.name),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (user.isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, size: 16, color: AppColors.verifiedBlue),
          ],
          if (user.isAdmin) ...[
            const SizedBox(width: 4),
            const Icon(Icons.admin_panel_settings,
                size: 16, color: AppColors.gold),
          ],
        ],
      ),
      subtitle: Text(user.phone),
      trailing: user.isBanned
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'محظور',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : const Icon(Icons.chevron_left, color: AppColors.textHint),
    );
  }
}
