import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

class GetChatsUseCase {
  final ChatRepository _repository;
  GetChatsUseCase(this._repository);
  Stream<List<Chat>> call(String userId) => _repository.watchChats(userId);
}
