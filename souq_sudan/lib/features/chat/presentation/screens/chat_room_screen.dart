import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/image_message_widget.dart';
import '../widgets/message_bubble.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String chatId;
  final Chat? chat;

  const ChatRoomScreen({super.key, required this.chatId, this.chat});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  int _previousMessageCount = 0;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markRead();
      _jumpToBottom();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isVisible = state == AppLifecycleState.resumed;
    if (_isVisible) _markRead();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  void _markRead() {
    ref.read(chatNotifierProvider.notifier).markAsRead(widget.chatId);
  }

  void _jumpToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.minScrollExtent);
  }

  void _animateToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Chat? _resolveChat(WidgetRef ref) {
    if (widget.chat != null) return widget.chat;
    final chats = ref.read(userChatsStreamProvider).value ?? const [];
    for (final c in chats) {
      if (c.id == widget.chatId) return c;
    }
    return null;
  }

  String _otherUserId(Chat? chat, String currentUserId) {
    if (chat == null) return '';
    return chat.getOtherUserId(currentUserId);
  }

  Future<void> _handleSendText(String text) async {
    final user = ref.read(currentUserProvider).value;
    final chat = _resolveChat(ref);
    if (user == null || chat == null) return;
    final receiverId = _otherUserId(chat, user.id);
    await ref.read(chatNotifierProvider.notifier).sendTextMessage(
          chatId: widget.chatId,
          receiverId: receiverId,
          text: text,
        );
    _showErrorIfAny();
  }

  Future<void> _handleSendImage(File file) async {
    final user = ref.read(currentUserProvider).value;
    final chat = _resolveChat(ref);
    if (user == null || chat == null) return;
    final receiverId = _otherUserId(chat, user.id);
    await ref.read(chatNotifierProvider.notifier).sendImageMessage(
          chatId: widget.chatId,
          receiverId: receiverId,
          imageFile: file,
        );
    _showErrorIfAny();
  }

  void _showErrorIfAny() {
    final state = ref.read(chatNotifierProvider);
    state.whenOrNull(
      error: (err, _) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString())),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final messagesAsync =
        ref.watch(chatMessagesStreamProvider(widget.chatId));
    final notifierState = ref.watch(chatNotifierProvider);

    // Auto mark as read when new messages arrive while screen is visible.
    ref.listen<AsyncValue<List<Message>>>(
      chatMessagesStreamProvider(widget.chatId),
      (prev, next) {
        next.whenData((msgs) {
          if (msgs.length > _previousMessageCount) {
            _previousMessageCount = msgs.length;
            if (_isVisible) _markRead();
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _animateToBottom());
          }
        });
      },
    );

    final chat = _resolveChat(ref);
    final user = currentUserAsync.value;
    final otherName = (chat != null && user != null)
        ? chat.getOtherUserName(user.id)
        : 'محادثة';
    final otherImage =
        (chat != null && user != null) ? chat.getOtherUserImage(user.id) : null;
    final otherUserId =
        (chat != null && user != null) ? chat.getOtherUserId(user.id) : '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: InkWell(
          onTap: otherUserId.isEmpty
              ? null
              : () => context.push('/user/$otherUserId'),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: (otherImage != null && otherImage.isNotEmpty)
                      ? CachedImageWidget(
                          imageUrl: otherImage,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.white24,
                          alignment: Alignment.center,
                          child: Text(
                            Helpers.getInitials(otherName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  otherName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (chat != null && chat.adId != null && chat.adTitle != null)
            _AdPinnedBanner(chat: chat),
          Expanded(
            child: currentUserAsync.when(
              loading: () => const LoadingWidget(),
              error: (err, _) => AppErrorWidget(message: err.toString()),
              data: (loggedUser) {
                if (loggedUser == null) {
                  return const Center(
                    child: Text('يرجى تسجيل الدخول لعرض الرسائل'),
                  );
                }
                return messagesAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (err, _) => AppErrorWidget(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(
                        chatMessagesStreamProvider(widget.chatId)),
                  ),
                  data: (messages) {
                    if (messages.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'لا توجد رسائل بعد\nابدأ المحادثة بإرسال رسالة',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }
                    final reversed = messages.reversed.toList();
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: reversed.length,
                      itemBuilder: (context, index) {
                        final msg = reversed[index];
                        final isMe = msg.senderId == loggedUser.id;
                        if (msg.type == MessageType.image) {
                          return ImageMessageWidget(
                              message: msg, isMe: isMe);
                        }
                        return MessageBubble(message: msg, isMe: isMe);
                      },
                    );
                  },
                );
              },
            ),
          ),
          ChatInputBar(
            enabled: !notifierState.isLoading,
            onSendText: _handleSendText,
            onSendImage: _handleSendImage,
          ),
        ],
      ),
    );
  }
}

class _AdPinnedBanner extends StatelessWidget {
  final Chat chat;
  const _AdPinnedBanner({required this.chat});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: InkWell(
        onTap: () {
          if (chat.adId != null) {
            context.push('/ads/${chat.adId}');
          }
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.divider),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: (chat.adImage != null && chat.adImage!.isNotEmpty)
                      ? CachedImageWidget(
                          imageUrl: chat.adImage,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.divider,
                          child: const Icon(
                            Icons.local_offer_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'بخصوص الإعلان',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      chat.adTitle ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
