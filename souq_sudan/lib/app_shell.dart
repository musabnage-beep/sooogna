import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/chat/presentation/providers/chat_provider.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _tabs = <_TabInfo>[
    _TabInfo(path: '/home',    icon: Icons.home_outlined,            activeIcon: Icons.home_rounded,         label: 'الرئيسية',   requiresAuth: false),
    _TabInfo(path: '/saved',   icon: Icons.favorite_border_rounded,  activeIcon: Icons.favorite_rounded,     label: 'المفضلة',    requiresAuth: true),
    _TabInfo(path: '/chats',   icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'الرسائل',    requiresAuth: true),
    _TabInfo(path: '/profile', icon: Icons.person_outline_rounded,   activeIcon: Icons.person_rounded,       label: 'حسابي',      requiresAuth: true),
  ];

  static const _authRequiredIndices = {1, 2, 3};

  int _indexForLocation(String location) {
    for (int i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i].path || location.startsWith('${_tabs[i].path}/')) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location   = GoRouterState.of(context).uri.path;
    final idx        = _indexForLocation(location);
    final isLoggedIn = ref.watch(currentUserProvider).value != null;
    final unreadCount = ref.watch(totalUnreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      floatingActionButton: _AddFab(isLoggedIn: isLoggedIn),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(
        tabs: _tabs,
        currentIndex: idx,
        unreadCount: unreadCount,
        isLoggedIn: isLoggedIn,
        authRequiredIndices: _authRequiredIndices,
      ),
    );
  }
}

class _AddFab extends StatelessWidget {
  final bool isLoggedIn;
  const _AddFab({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (!isLoggedIn) {
          context.push('/login');
          return;
        }
        context.push('/create-ad');
      },
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7A00), Color(0xFFFFB000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF7A00).withValues(alpha: 0.40),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final List<_TabInfo> tabs;
  final int currentIndex;
  final int unreadCount;
  final bool isLoggedIn;
  final Set<int> authRequiredIndices;

  const _BottomBar({
    required this.tabs,
    required this.currentIndex,
    required this.unreadCount,
    required this.isLoggedIn,
    required this.authRequiredIndices,
  });

  void _onTap(BuildContext context, int i) {
    if (i == currentIndex) return;
    HapticFeedback.selectionClick();
    if (authRequiredIndices.contains(i) && !isLoggedIn) {
      context.push('/login');
      return;
    }
    context.go(tabs[i].path);
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      color: AppColors.surface,
      elevation: 0,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(tab: tabs[0], isActive: currentIndex == 0, onTap: () => _onTap(context, 0)),
            _NavItem(tab: tabs[1], isActive: currentIndex == 1, onTap: () => _onTap(context, 1)),
            const SizedBox(width: 58),
            _NavItem(
              tab: tabs[2],
              isActive: currentIndex == 2,
              badge: unreadCount > 0 ? (unreadCount > 99 ? '99+' : '$unreadCount') : null,
              onTap: () => _onTap(context, 2),
            ),
            _NavItem(tab: tabs[3], isActive: currentIndex == 3, onTap: () => _onTap(context, 3)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _TabInfo tab;
  final bool isActive;
  final String? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textHint;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isActive ? tab.activeIcon : tab.icon, color: color, size: 24),
                if (badge != null)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 18,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabInfo {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool requiresAuth;

  const _TabInfo({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.requiresAuth = false,
  });
}
