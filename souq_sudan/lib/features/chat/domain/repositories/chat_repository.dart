import '../entities/chat_entity.dart';
import '../entities/message_entity.dart';
import '../../../../core/utils/result.dart';

abstract class ChatRepository {
  Stream<List<Chat>> watchChats(String userId);
  Stream<List<Message>> watchMessages(String chatId);
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
  });
  Future<Result<void>> sendTextMessage({required String chatId, required String senderId, required String text});
  Future<Result<void>> sendImageMessage({required String chatId, required String senderId, required String localImagePath});
  Future<Result<void>> markMessagesAsRead(String chatId, String currentUserId);
  Future<Result<List<Message>>> getMessagesPage(String chatId, {Object? lastDoc, int limit = 50});
}
