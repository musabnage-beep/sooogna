import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_entity.dart';

class ChatModel {
  final String id;
  final List<String> userIds;
  final Map<String, String> userNames;
  final Map<String, String?> userImages;
  final String? adId;
  final String? adTitle;
  final String? adImage;
  final String lastMessage;
  final String lastMessageSenderId;
  final Timestamp updatedAt;
  final Map<String, int> unreadCount;

  const ChatModel({
    required this.id,
    required this.userIds,
    required this.userNames,
    required this.userImages,
    this.adId,
    this.adTitle,
    this.adImage,
    this.lastMessage = '',
    this.lastMessageSenderId = '',
    required this.updatedAt,
    required this.unreadCount,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    final userNamesRaw = (map['userNames'] as Map<String, dynamic>?) ?? {};
    final userImagesRaw = (map['userImages'] as Map<String, dynamic>?) ?? {};
    final unreadRaw = (map['unreadCount'] as Map<String, dynamic>?) ?? {};
    return ChatModel(
      id: id,
      userIds: List<String>.from(map['userIds'] as List? ?? []),
      userNames: userNamesRaw.map((k, v) => MapEntry(k, v as String? ?? '')),
      userImages: userImagesRaw.map((k, v) => MapEntry(k, v as String?)),
      adId: map['adId'] as String?,
      adTitle: map['adTitle'] as String?,
      adImage: map['adImage'] as String?,
      lastMessage: (map['lastMessage'] as String?) ?? '',
      lastMessageSenderId: (map['lastMessageSenderId'] as String?) ?? '',
      updatedAt: (map['updatedAt'] as Timestamp?) ?? Timestamp.now(),
      unreadCount: unreadRaw.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }

  factory ChatModel.fromDocument(DocumentSnapshot doc) {
    return ChatModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userIds': userIds,
      'userNames': userNames,
      'userImages': userImages,
      'adId': adId,
      'adTitle': adTitle,
      'adImage': adImage,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'updatedAt': updatedAt,
      'unreadCount': unreadCount,
    };
  }

  Chat toEntity() {
    return Chat(
      id: id,
      userIds: userIds,
      userNames: userNames,
      userImages: userImages,
      adId: adId,
      adTitle: adTitle,
      adImage: adImage,
      lastMessage: lastMessage,
      lastMessageSenderId: lastMessageSenderId,
      updatedAt: updatedAt.toDate(),
      unreadCount: unreadCount,
    );
  }
}
