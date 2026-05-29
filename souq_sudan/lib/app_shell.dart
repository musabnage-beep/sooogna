import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/chat/presentation/providers/chat_provider.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _tabs = <_TabInfo>[
    _TabInfo(path: '/home', icon: Icons.home_outlined, activeIcon: Icons.home, label: 'الرئيسية'),
    _TabInfo(path: '/chats', icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'المحادثات'),
    _TabInfo(path: '/profile', icon: Icons.person_outline, activeIcon: Icons.person, label: 'حسابي'),
  ];

  int _indexForLocation(String location) {
    for (int i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i].path || location.startsWith('${_tabs[i].path}/')) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _indexForLocation(location);
    final unreadCount = ref.watch(totalUnreadCountProvider);

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-ad'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('إضافة إعلان'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == currentIndex) return;
          context.go(_tabs[index].path);
        },
        items: List.generate(_tabs.length, (i) {
          final tab = _tabs[i];
          final isActive = i == currentIndex;
          Widget iconWidget = Icon(isActive ? tab.activeIcon : tab.icon);
          if (i == 1 && unreadCount > 0) {
            iconWidget = Stack(
              clipBehavior: Clip.none,
              children: [
                iconWidget,
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          }
          return BottomNavigationBarItem(
            icon: iconWidget,
            label: tab.label,
          );
        }),
      ),
    );
  }
}

class _TabInfo {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabInfo({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
