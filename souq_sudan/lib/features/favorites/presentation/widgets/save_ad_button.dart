import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../ads/domain/entities/ad_entity.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../providers/favorites_provider.dart';

/// Heart toggle that saves/removes an ad from the user's favorites (Feature 8).
class SaveAdButton extends ConsumerWidget {
  final Ad ad;
  final Color? color;

  const SaveAdButton({super.key, required this.ad, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoriteIdsProvider).value ?? const <String>{};
    final isSaved = ids.contains(ad.id);

    return IconButton(
      tooltip: isSaved ? 'إزالة من المحفوظات' : 'حفظ',
      icon: Icon(
        isSaved ? Icons.favorite : Icons.favorite_border,
        color: isSaved ? AppColors.error : color,
      ),
      onPressed: () async {
        final result = await ref
            .read(favoritesNotifierProvider.notifier)
            .toggle(ad, isSaved);
        if (result == true) {
          ref.read(analyticsRepositoryProvider).bumpSaved(ad.userId);
        }
        if (result == null || !context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ? 'تم الحفظ' : 'تمت الإزالة'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}
