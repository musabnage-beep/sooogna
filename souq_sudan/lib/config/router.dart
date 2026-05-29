import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_shell.dart';
import '../features/admin/presentation/screens/admin_ad_review_screen.dart';
import '../features/admin/presentation/screens/admin_ads_screen.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/admin/presentation/screens/admin_reports_screen.dart';
import '../features/admin/presentation/screens/admin_user_detail_screen.dart';
import '../features/admin/presentation/screens/admin_users_screen.dart';
import '../features/ads/presentation/screens/ad_detail_screen.dart';
import '../features/ads/presentation/screens/category_ads_screen.dart';
import '../features/ads/presentation/screens/create_ad_screen.dart';
import '../features/ads/presentation/screens/edit_ad_screen.dart';
import '../features/ads/presentation/screens/home_screen.dart';
import '../features/ads/presentation/screens/my_ads_screen.dart';
import '../features/ads/presentation/screens/search_screen.dart';
import '../features/auth/domain/entities/user_entity.dart' show AppUser;
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/banned_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/otp_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/chat/domain/entities/chat_entity.dart';
import '../features/chat/presentation/screens/chat_list_screen.dart';
import '../features/chat/presentation/screens/chat_room_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/settings_screen.dart';
import '../features/profile/presentation/screens/user_profile_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

const _publicRoutes = <String>{
  '/splash',
  '/login',
  '/otp',
  '/register',
};

final routerProvider = Provider<GoRouter>((ref) {
  final authChanges = ValueNotifier<int>(0);
  ref.listen(authStateChangesProvider, (_, __) => authChanges.value++);
  ref.listen(currentUserProvider, (_, __) => authChanges.value++);
  ref.onDispose(authChanges.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: authChanges,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == '/splash') return null;

      final firebaseAuth = ref.read(authStateChangesProvider).value;
      final appUserAsync = ref.read(currentUserProvider);

      if (firebaseAuth == null) {
        if (_publicRoutes.contains(path)) return null;
        return '/login';
      }

      // Authenticated but profile not yet loaded -> wait
      if (appUserAsync.isLoading) return null;

      final appUser = appUserAsync.value;
      if (appUser == null) {
        if (path == '/register' || path == '/banned') return null;
        return '/register';
      }

      if (appUser.isBanned) {
        if (path == '/banned') return null;
        return '/banned';
      }

      // Logged in with profile: block public auth routes
      if (_publicRoutes.contains(path) || path == '/register') {
        return '/home';
      }

      // Admin gate
      if (path.startsWith('/admin') && !appUser.isAdmin) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (_, state) {
          final verificationId = state.extra as String? ?? '';
          return OTPScreen(verificationId: verificationId);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/banned',
        builder: (_, __) => const BannedScreen(),
      ),

      // Shell with bottom nav
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/chats',
            builder: (_, __) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // Full-screen routes
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/category/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            CategoryAdsScreen(categoryId: state.pathParameters['id'] ?? ''),
      ),

      // Ads
      GoRoute(
        path: '/ads/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            AdDetailScreen(adId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/create-ad',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const CreateAdScreen(),
      ),
      GoRoute(
        path: '/edit-ad/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            EditAdScreen(adId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/my-ads',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const MyAdsScreen(),
      ),

      // Chat room
      GoRoute(
        path: '/chat/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => ChatRoomScreen(
          chatId: state.pathParameters['id'] ?? '',
          chat: state.extra is Chat ? state.extra as Chat : null,
        ),
      ),

      // Profile
      GoRoute(
        path: '/edit-profile',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/user/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            UserProfileScreen(userId: state.pathParameters['id'] ?? ''),
      ),

      // Admin
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/users/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            AdminUserDetailScreen(userId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/admin/ads',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const AdminAdsScreen(),
      ),
      GoRoute(
        path: '/admin/ads/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            AdminAdReviewScreen(adId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/admin/reports',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const AdminReportsScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      appBar: AppBar(title: const Text('خطأ')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 12),
            Text('المسار غير موجود: ${state.uri.path}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  _rootKey.currentContext?.go('/home'),
              child: const Text('الذهاب للرئيسية'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Re-exports to keep imports tidy if needed.
typedef CurrentAppUser = AppUser;
