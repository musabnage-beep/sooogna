import '../../../../core/enums/app_enums.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String? text;
  final String? image;
  final MessageType type;
  final bool isRead;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.text,
    this.image,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });
}
