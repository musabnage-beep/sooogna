import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../providers/admin_provider.dart';
import '../widgets/user_management_tile.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'المستخدمون',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو الهاتف...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(allUsersProvider),
        child: usersAsync.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => AppErrorWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(allUsersProvider),
          ),
          data: (users) {
            final filtered = _query.isEmpty
                ? users
                : users.where((u) {
                    final q = _query.toLowerCase();
                    return u.name.toLowerCase().contains(q) ||
                        u.phone.contains(q);
                  }).toList();

            if (filtered.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.people_outline,
                message: 'لا يوجد مستخدمون',
              );
            }

            return ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => UserManagementTile(
                user: filtered[i],
                onTap: () => context.push('/admin/users/${filtered[i].id}'),
              ),
            );
          },
        ),
      ),
    );
  }
}
