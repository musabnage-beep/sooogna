import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_tile.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final chatsAsync = ref.watch(userChatsStreamProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'المحادثات', showBack: false),
      body: currentUserAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, _) => AppErrorWidget(
          message: 'تعذّر تحميل بيانات المستخدم',
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
        data: (user) {
          if (user == null) {
            return const EmptyStateWidget(
              icon: Icons.lock_outline,
              message: 'يرجى تسجيل الدخول لعرض المحادثات',
            );
          }
          return chatsAsync.when(
            loading: () => const LoadingWidget(),
            error: (err, _) => AppErrorWidget(
              message: err.toString(),
              onRetry: () => ref.invalidate(userChatsStreamProvider),
            ),
            data: (chats) {
              if (chats.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.chat_bubble_outline,
                  message: 'لا توجد محادثات بعد\nابدأ محادثة من خلال صفحة الإعلان',
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(userChatsStreamProvider);
                  await Future<void>.delayed(
                      const Duration(milliseconds: 400));
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 76,
                    endIndent: 12,
                  ),
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return ChatTile(
                      chat: chat,
                      currentUserId: user.id,
                      onTap: () =>
                          context.push('/chat/${chat.id}', extra: chat),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
