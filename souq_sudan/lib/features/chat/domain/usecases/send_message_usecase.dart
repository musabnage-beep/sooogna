import '../repositories/chat_repository.dart';
import '../../../../core/utils/result.dart';

class SendMessageUseCase {
  final ChatRepository _repository;
  SendMessageUseCase(this._repository);

  Future<Result<void>> sendText({required String chatId, required String senderId, required String text}) {
    return _repository.sendTextMessage(chatId: chatId, senderId: senderId, text: text);
  }

  Future<Result<void>> sendImage({required String chatId, required String senderId, required String localImagePath}) {
    return _repository.sendImageMessage(chatId: chatId, senderId: senderId, localImagePath: localImagePath);
  }
}
