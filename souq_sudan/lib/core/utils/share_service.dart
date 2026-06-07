import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

/// Centralised sharing for ads, stores and service profiles (Feature 9).
/// Uses platform share-intent URLs (no extra dependency) so it works on web.
class ShareService {
  const ShareService._();

  /// Canonical, SEO-friendly URL for an ad's static snapshot page.
  static String adUrl(String adId) => '${AppConstants.webBaseUrl}/ad/$adId.html';

  /// Canonical URL for a store page.
  static String storeUrl(String storeId) =>
      '${AppConstants.webBaseUrl}/store/$storeId';

  /// Canonical URL for a service provider profile.
  static String serviceUrl(String userId) =>
      '${AppConstants.webBaseUrl}/services/$userId';

  static Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> shareToWhatsApp(String text) =>
      _launch(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}'));

  /// Opens a WhatsApp chat with a specific number (digits only, with country code).
  static Future<void> contactWhatsApp(String number, {String? text}) {
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    final suffix = text != null ? '?text=${Uri.encodeComponent(text)}' : '';
    return _launch(Uri.parse('https://wa.me/$digits$suffix'));
  }

  /// Starts a phone dial to [number].
  static Future<void> dialPhone(String number) =>
      _launch(Uri.parse('tel:${number.replaceAll(RegExp(r'\s'), '')}'));

  static Future<void> shareToTelegram(String url, String text) => _launch(Uri.parse(
      'https://t.me/share/url?url=${Uri.encodeComponent(url)}&text=${Uri.encodeComponent(text)}'));

  static Future<void> shareToFacebook(String url) => _launch(Uri.parse(
      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url)}'));

  static Future<void> copyLink(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الرابط')),
    );
  }

  /// Shows a bottom sheet with the four share channels.
  static Future<void> showShareSheet(
    BuildContext context, {
    required String url,
    required String message,
  }) {
    final fullText = '$message\n$url';
    return showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text('مشاركة عبر',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareButton(
                  icon: Icons.chat,
                  color: const Color(0xFF25D366),
                  label: 'واتساب',
                  onTap: () {
                    Navigator.pop(ctx);
                    shareToWhatsApp(fullText);
                  },
                ),
                _ShareButton(
                  icon: Icons.send,
                  color: const Color(0xFF0088CC),
                  label: 'تيليجرام',
                  onTap: () {
                    Navigator.pop(ctx);
                    shareToTelegram(url, message);
                  },
                ),
                _ShareButton(
                  icon: Icons.facebook,
                  color: const Color(0xFF1877F2),
                  label: 'فيسبوك',
                  onTap: () {
                    Navigator.pop(ctx);
                    shareToFacebook(url);
                  },
                ),
                _ShareButton(
                  icon: Icons.link,
                  color: AppColors.textSecondary,
                  label: 'نسخ الرابط',
                  onTap: () {
                    Navigator.pop(ctx);
                    copyLink(context, url);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
