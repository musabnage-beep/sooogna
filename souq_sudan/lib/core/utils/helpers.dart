import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class Helpers {
  Helpers._();

  static String formatPrice(double price) {
    if (price == 0) return 'مجاناً';
    final formatter = NumberFormat('#,###');
    return '${formatter.format(price)} ج.س';
  }

  static String formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy', 'ar');
    return formatter.format(date);
  }

  static String timeAgo(DateTime date) {
    return timeago.format(date, locale: 'ar');
  }

  static String formatMemberSince(DateTime date) {
    final formatter = DateFormat('MMMM yyyy', 'ar');
    return 'منذ ${formatter.format(date)}';
  }

  static List<String> extractSearchKeywords(String title) {
    final words = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2)
        .toSet()
        .toList();
    return words;
  }

  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static void initTimeago() {
    timeago.setLocaleMessages('ar', timeago.ArMessages());
  }
}
