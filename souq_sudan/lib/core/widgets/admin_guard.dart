import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';

/// Defense-in-depth wrapper for admin-only screens. The router redirect is the
/// primary gate and Firestore rules are the server backstop, but during the
/// brief window where the profile is still loading the redirect can't yet know
/// the user's role. This guard renders a neutral screen until the role is known
/// and refuses to render the admin UI for non-admins.
class AdminGuard extends ConsumerWidget {
  final Widget child;
  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('تعذّر التحقق من الصلاحيات')),
      ),
      data: (user) {
        if (user == null || !user.isAdmin) {
          return const Scaffold(
            body: Center(child: Text('غير مصرّح لك بالدخول')),
          );
        }
        return child;
      },
    );
  }
}
