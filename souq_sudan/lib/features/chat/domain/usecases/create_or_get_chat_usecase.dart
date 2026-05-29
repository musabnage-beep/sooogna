import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';
import '../../../../core/utils/result.dart';

class CreateOrGetChatUseCase {
  final ChatRepository _repository;
  CreateOrGetChatUseCase(this._repository);

  Future<Result<Chat>> call({
    required String currentUserId,
    required String currentUserName,
    required String? currentUserImage,
    required String otherUserId,
    required String otherUserName,
    required String? otherUserImage,
    String? adId,
    String? adTitle,
    String? adImage,
  }) {
    return _repository.createOrGetChat(
      currentUserId: currentUserId,
      currentUserName: currentUserName,
      currentUserImage: currentUserImage,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserImage: otherUserImage,
      adId: adId,
      adTitle: adTitle,
      adImage: adImage,
    );
  }
}
