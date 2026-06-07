import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../../../core/constants/app_constants.dart';

class ChatRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ChatRemoteDataSource({required FirebaseFirestore firestore, required FirebaseStorage storage})
      : _firestore = firestore, _storage = storage;

  CollectionReference get _chatsRef => _firestore.collection('chats');

  Stream<List<ChatModel>> watchChats(String userId) {
    return _chatsRef
        .where('userIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatModel.fromDocument(d)).toList());
  }

  Stream<List<MessageModel>> watchMessages(String chatId) {
    // Only stream the most recent page of messages to bound memory and reads;
    // older history is fetched on demand via [getMessagesPage]. We query
    // newest-first then reverse so the UI still renders oldest→newest.
    return _chatsRef
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.messagesPageSize)
        .snapshots()
        .map((snap) =>
            snap.docs.reversed.map((d) => MessageModel.fromDocument(d)).toList());
  }

  Future<ChatModel?> findExistingChat(String currentUserId, String otherUserId, String? adId) async {
    final snap = await _chatsRef
        .where('userIds', arrayContains: currentUserId)
        .orderBy('updatedAt', descending: true)
        .limit(AppConstants.maxUserChatsScan)
        .get();

    for (final doc in snap.docs) {
      final chat = ChatModel.fromDocument(doc);
      if (chat.userIds.contains(otherUserId)) {
        if (adId == null || chat.adId == adId) return chat;
      }
    }
    return null;
  }

  Future<ChatModel> createChat({
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
    final docRef = _chatsRef.doc();
    final data = {
      'userIds': [currentUserId, otherUserId],
      'userNames': {currentUserId: currentUserName, otherUserId: otherUserName},
      'userImages': {currentUserId: currentUserImage, otherUserId: otherUserImage},
      'adId': adId,
      'adTitle': adTitle,
      'adImage': adImage,
      'lastMessage': '',
      'lastMessageSenderId': '',
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCount': {currentUserId: 0, otherUserId: 0},
    };
    await docRef.set(data);
    final doc = await docRef.get();
    return ChatModel.fromDocument(doc);
  }

  Future<void> sendTextMessage({required String chatId, required String senderId, required String otherUserId, required String text}) async {
    final msgRef = _chatsRef.doc(chatId).collection('messages').doc();
    final batch = _firestore.batch();

    batch.set(msgRef, {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'image': null,
      'type': 'text',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(_chatsRef.doc(chatId), {
      'lastMessage': text.length > 100 ? text.substring(0, 100) : text,
      'lastMessageSenderId': senderId,
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCount.$otherUserId': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<void> sendImageMessage({required String chatId, required String senderId, required String otherUserId, required String localImagePath}) async {
    final msgRef = _chatsRef.doc(chatId).collection('messages').doc();
    final messageId = msgRef.id;

    final file = File(localImagePath);
    final compressed = await ImageCompressor.compressToMaxSize(file, AppConstants.maxImageSizeBytes);
    final storageRef = _storage.ref('chat_images/$chatId/$messageId.jpg');
    await storageRef.putFile(compressed);
    final imageUrl = await storageRef.getDownloadURL();
    await ImageCompressor.deleteIfTemp(compressed);

    final batch = _firestore.batch();
    batch.set(msgRef, {
      'chatId': chatId,
      'senderId': senderId,
      'text': null,
      'image': imageUrl,
      'type': 'image',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_chatsRef.doc(chatId), {
      'lastMessage': '📷 صورة',
      'lastMessageSenderId': senderId,
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCount.$otherUserId': FieldValue.increment(1),
    });
    await batch.commit();
  }

  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    final batch = _firestore.batch();

    // Reset unread count
    batch.update(_chatsRef.doc(chatId), {'unreadCount.$currentUserId': 0});

    // Mark unread messages as read
    final unread = await _chatsRef.doc(chatId).collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUserId)
        .get();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  Future<List<MessageModel>> getMessagesPage(String chatId, {DocumentSnapshot? lastDoc, int limit = 50}) async {
    Query query = _chatsRef.doc(chatId).collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (lastDoc != null) query = query.startAfterDocument(lastDoc);
    final snap = await query.get();
    return snap.docs.reversed.map((d) => MessageModel.fromDocument(d)).toList();
  }
}
