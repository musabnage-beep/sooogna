class AppNotification {
  final String id;
  final String type; // 'chat', 'ad_status', 'review'
  final String title;
  final String body;
  final String? targetId; // chatId, adId, etc.
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.targetId,
    required this.createdAt,
    this.isRead = false,
  });
}
