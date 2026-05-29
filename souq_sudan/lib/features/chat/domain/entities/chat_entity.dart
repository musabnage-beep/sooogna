class Chat {
  final String id;
  final List<String> userIds;
  final Map<String, String> userNames;
  final Map<String, String?> userImages;
  final String? adId;
  final String? adTitle;
  final String? adImage;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime updatedAt;
  final Map<String, int> unreadCount;

  const Chat({
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

  String getOtherUserId(String currentUserId) {
    return userIds.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  String getOtherUserName(String currentUserId) {
    final otherId = getOtherUserId(currentUserId);
    return userNames[otherId] ?? 'مستخدم';
  }

  String? getOtherUserImage(String currentUserId) {
    final otherId = getOtherUserId(currentUserId);
    return userImages[otherId];
  }

  int getUnreadCount(String userId) => unreadCount[userId] ?? 0;
}
