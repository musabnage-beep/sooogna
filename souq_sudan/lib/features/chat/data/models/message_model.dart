import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/message_entity.dart';
import '../../../../core/enums/app_enums.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String? text;
  final String? image;
  final String type;
  final bool isRead;
  final Timestamp createdAt;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.text,
    this.image,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      chatId: (map['chatId'] as String?) ?? '',
      senderId: (map['senderId'] as String?) ?? '',
      text: map['text'] as String?,
      image: map['image'] as String?,
      type: (map['type'] as String?) ?? 'text',
      isRead: (map['isRead'] as bool?) ?? false,
      createdAt: (map['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  factory MessageModel.fromDocument(DocumentSnapshot doc) {
    return MessageModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'image': image,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  Message toEntity() {
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      text: text,
      image: image,
      type: MessageTypeExtension.fromString(type),
      isRead: isRead,
      createdAt: createdAt.toDate(),
    );
  }
}
