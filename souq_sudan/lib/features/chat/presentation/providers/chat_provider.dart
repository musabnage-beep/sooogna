import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ads/presentation/providers/ads_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';

// Data source
final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

// Repository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.watch(chatRemoteDataSourceProvider));
});

// User chats stream
final userChatsStreamProvider = StreamProvider<List<Chat>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) {
    return Stream<List<Chat>>.value(const []);
  }
  return ref.watch(chatRepositoryProvider).watchChats(user.id);
});

// Chat messages stream
final chatMessagesStreamProvider =
    StreamProvider.family<List<Message>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).watchMessages(chatId);
});

// Total unread count for the current user across all chats
final totalUnreadCountProvider = Provider<int>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return 0;
  final chats = ref.watch(userChatsStreamProvider).value;
  if (chats == null || chats.isEmpty) return 0;
  var total = 0;
  for (final chat in chats) {
    total += chat.getUnreadCount(user.id);
  }
  return total;
});

// Chat actions notifier
class ChatNotifier extends StateNotifier<AsyncValue<void>> {
  final ChatRepository _repository;
  final Ref _ref;

  ChatNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<String?> createOrGetChat({
    required String otherUserId,
    required String otherUserName,
    String? otherUserImage,
    String? adId,
    String? adTitle,
    String? adImage,
  }) async {
    final user = _ref.read(currentUserProvider).value;
    if (user == null) {
      state = AsyncValue.error('يرجى تسجيل الدخول أولاً', StackTrace.current);
      return null;
    }
    state = const AsyncValue.loading();
    final result = await _repository.createOrGetChat(
      currentUserId: user.id,
      currentUserName: user.name,
      currentUserImage: user.profileImage,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserImage: otherUserImage,
      adId: adId,
      adTitle: adTitle,
      adImage: adImage,
    );
    return result.when(
      success: (chat) {
        state = const AsyncValue.data(null);
        return chat.id;
      },
      failure: (message, _) {
        state = AsyncValue.error(message, StackTrace.current);
        return null;
      },
    );
  }

  Future<void> sendTextMessage({
    required String chatId,
    required String receiverId,
    required String text,
  }) async {
    final user = _ref.read(currentUserProvider).value;
    if (user == null) {
      state = AsyncValue.error('يرجى تسجيل الدخول أولاً', StackTrace.current);
      return;
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final result = await _repository.sendTextMessage(
      chatId: chatId,
      senderId: user.id,
      text: trimmed,
    );
    result.when(
      success: (_) => state = const AsyncValue.data(null),
      failure: (message, _) =>
          state = AsyncValue.error(message, StackTrace.current),
    );
  }

  Future<void> sendImageMessage({
    required String chatId,
    required String receiverId,
    required File imageFile,
  }) async {
    final user = _ref.read(currentUserProvider).value;
    if (user == null) {
      state = AsyncValue.error('يرجى تسجيل الدخول أولاً', StackTrace.current);
      return;
    }
    state = const AsyncValue.loading();
    final result = await _repository.sendImageMessage(
      chatId: chatId,
      senderId: user.id,
      localImagePath: imageFile.path,
    );
    result.when(
      success: (_) => state = const AsyncValue.data(null),
      failure: (message, _) =>
          state = AsyncValue.error(message, StackTrace.current),
    );
  }

  Future<void> markAsRead(String chatId) async {
    final user = _ref.read(currentUserProvider).value;
    if (user == null) return;
    await _repository.markMessagesAsRead(chatId, user.id);
  }
}

final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<void>>((ref) {
  return ChatNotifier(ref.watch(chatRepositoryProvider), ref);
});
