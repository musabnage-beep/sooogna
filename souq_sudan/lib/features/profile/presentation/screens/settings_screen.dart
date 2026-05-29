import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled =
          prefs.getBool(AppConstants.notificationsEnabledKey) ?? true;
      _loading = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.notificationsEnabledKey, value);
    if (!mounted) return;
    setState(() => _notificationsEnabled = value);
  }

  Future<void> _clearCache() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'مسح الذاكرة المؤقتة',
      message: 'هل تريد مسح عمليات البحث الأخيرة والبيانات المؤقتة؟',
      confirmText: 'مسح',
    );
    if (!confirmed) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.recentSearchesKey);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم مسح الذاكرة المؤقتة')),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _contactSupport() async {
    final number = AppConstants.supportWhatsAppNumber;
    final uri = Uri.parse(
        'https://wa.me/$number?text=${Uri.encodeComponent('مرحباً، أحتاج للمساعدة في تطبيق سوق السودان')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _deleteAccount() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'حذف الحساب',
      message:
          'سيتم حذف حسابك وجميع بياناتك بشكل نهائي. لا يمكن التراجع عن هذه العملية.',
      confirmText: 'حذف نهائي',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    final ok =
        await ref.read(profileNotifierProvider.notifier).deleteAccount(user.id);

    if (!mounted) return;

    if (ok) {
      await ref.read(authNotifierProvider.notifier).logout();
      if (!mounted) return;
      context.go('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الحساب')),
      );
    } else {
      final err = ref.read(profileNotifierProvider).error?.toString() ??
          'تعذر حذف الحساب';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'الإعدادات'),
      body: ListView(
        children: [
          const _SectionHeader(title: 'التفضيلات'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined,
                color: AppColors.primary),
            title: const Text('الإشعارات'),
            subtitle: const Text('تلقي إشعارات الرسائل والإعلانات'),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          ListTile(
            leading:
                const Icon(Icons.cleaning_services_outlined, color: AppColors.primary),
            title: const Text('مسح الذاكرة المؤقتة'),
            onTap: _clearCache,
          ),
          const Divider(height: 1),
          const _SectionHeader(title: 'المساعدة والدعم'),
          ListTile(
            leading:
                const Icon(Icons.support_agent_outlined, color: AppColors.primary),
            title: const Text('تواصل معنا'),
            subtitle: const Text('عبر واتساب'),
            onTap: _contactSupport,
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined,
                color: AppColors.primary),
            title: const Text('سياسة الخصوصية'),
            onTap: () => _openUrl(AppConstants.privacyPolicyUrl),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined,
                color: AppColors.primary),
            title: const Text('الشروط والأحكام'),
            onTap: () => _openUrl(AppConstants.termsOfServiceUrl),
          ),
          const Divider(height: 1),
          const _SectionHeader(title: 'حول التطبيق'),
          const ListTile(
            leading: Icon(Icons.info_outline, color: AppColors.primary),
            title: Text('الإصدار'),
            trailing: Text(AppConstants.appVersion),
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: const Text(
              'حذف الحساب',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: _deleteAccount,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
