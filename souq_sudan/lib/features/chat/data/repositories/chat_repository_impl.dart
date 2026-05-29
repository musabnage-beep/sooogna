import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../../../../core/utils/result.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _dataSource;
  ChatRepositoryImpl(this._dataSource);

  String _mapError(dynamic e) {
    if (e is FirebaseException) return 'حدث خطأ في المحادثات (${e.code})';
    if (e is SocketException) return 'لا يوجد اتصال بالإنترنت';
    return 'حدث خطأ غير متوقع';
  }

  @override
  Stream<List<Chat>> watchChats(String userId) {
    return _dataSource.watchChats(userId).map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Stream<List<Message>> watchMessages(String chatId) {
    return _dataSource.watchMessages(chatId).map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Result<Chat>> createOrGetChat({
    required String currentUserId,
    required String currentUserName,
    required String? currentUserImage,
    required String otherUserId,
    required String otherUserName,
    required String? otherUserImage,
    String? adId,
    String? adTitle,
    String? adImage,
  }) async {
    try {
      if (currentUserId == otherUserId) {
        return const Result.failure('لا يمكنك محادثة نفسك');
      }
      final existing = await _dataSource.findExistingChat(currentUserId, otherUserId, adId);
      if (existing != null) return Result.success(existing.toEntity());

      final chat = await _dataSource.createChat(
        currentUserId: currentUserId, currentUserName: currentUserName,
        currentUserImage: currentUserImage, otherUserId: otherUserId,
        otherUserName: otherUserName, otherUserImage: otherUserImage,
        adId: adId, adTitle: adTitle, adImage: adImage,
      );
      return Result.success(chat.toEntity());
    } catch (e) { return Result.failure(_mapError(e)); }
  }

  @override
  Future<Result<void>> sendTextMessage({required String chatId, required String senderId, required String text}) async {
    try {
      // Get other user id from chat
      final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
      final userIds = List<String>.from(chatDoc.data()?['userIds'] as List? ?? []);
      final otherUserId = userIds.firstWhere((id) => id != senderId, orElse: () => '');
      await _dataSource.sendTextMessage(chatId: chatId, senderId: senderId, otherUserId: otherUserId, text: text);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapError(e)); }
  }

  @override
  Future<Result<void>> sendImageMessage({required String chatId, required String senderId, required String localImagePath}) async {
    try {
      final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
      final userIds = List<String>.from(chatDoc.data()?['userIds'] as List? ?? []);
      final otherUserId = userIds.firstWhere((id) => id != senderId, orElse: () => '');
      await _dataSource.sendImageMessage(chatId: chatId, senderId: senderId, otherUserId: otherUserId, localImagePath: localImagePath);
      return const Result.success(null);
    } catch (e) { return Result.failure(_mapError(e)); }
  }

  @override
  Future<Result<void>> markMessagesAsRead(String chatId, String currentUserId) async {
    try {
      await _dataSource.markMessagesAsRead(chatId, currentUserId);
      return const Result.success(null);
    } catch (e) { return const Result.success(null); }
  }

  @override
  Future<Result<List<Message>>> getMessagesPage(String chatId, {Object? lastDoc, int limit = 50}) async {
    try {
      final models = await _dataSource.getMessagesPage(chatId, lastDoc: lastDoc as DocumentSnapshot?, limit: limit);
      return Result.success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return Result.failure(_mapError(e)); }
  }
}
