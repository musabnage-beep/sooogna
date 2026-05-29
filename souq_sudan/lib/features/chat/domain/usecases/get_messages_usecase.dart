import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

class GetMessagesUseCase {
  final ChatRepository _repository;
  GetMessagesUseCase(this._repository);
  Stream<List<Message>> call(String chatId) => _repository.watchMessages(chatId);
}
