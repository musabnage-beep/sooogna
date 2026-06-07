import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class Helpers {
  Helpers._();

  // Arabic synonym groups — each word maps to its full synonym set
  static const Map<String, List<String>> _synonymGroups = {
    // Phones
    'هاتف':   ['هاتف', 'تلفون', 'جوال', 'موبايل', 'فون', 'ايفون', 'تليفون'],
    'تلفون':  ['هاتف', 'تلفون', 'جوال', 'موبايل', 'فون', 'ايفون', 'تليفون'],
    'تليفون': ['هاتف', 'تلفون', 'جوال', 'موبايل', 'فون', 'ايفون', 'تليفون'],
    'جوال':   ['هاتف', 'تلفون', 'جوال', 'موبايل', 'فون', 'ايفون', 'تليفون'],
    'موبايل': ['هاتف', 'تلفون', 'جوال', 'موبايل', 'فون', 'ايفون', 'تليفون'],
    'فون':    ['هاتف', 'تلفون', 'جوال', 'موبايل', 'فون', 'ايفون', 'تليفون'],
    'ايفون':  ['هاتف', 'تلفون', 'جوال', 'موبايل', 'فون', 'ايفون', 'تليفون'],
    // Cars
    'سيارة':  ['سيارة', 'عربية', 'مركبة', 'سيارات'],
    'عربية':  ['سيارة', 'عربية', 'مركبة', 'سيارات'],
    'مركبة':  ['سيارة', 'عربية', 'مركبة', 'سيارات'],
    // Houses
    'بيت':    ['بيت', 'منزل', 'شقة', 'مسكن', 'دار', 'بيوت'],
    'منزل':   ['بيت', 'منزل', 'شقة', 'مسكن', 'دار', 'بيوت'],
    'شقة':    ['بيت', 'منزل', 'شقة', 'مسكن', 'دار'],
    'مسكن':   ['بيت', 'منزل', 'شقة', 'مسكن', 'دار'],
    'دار':    ['بيت', 'منزل', 'شقة', 'مسكن', 'دار', 'بيوت'],
    // Computers / laptops
    'كمبيوتر': ['كمبيوتر', 'حاسوب', 'لابتوب', 'حاسب', 'كومبيوتر'],
    'حاسوب':   ['كمبيوتر', 'حاسوب', 'لابتوب', 'حاسب'],
    'لابتوب':  ['كمبيوتر', 'حاسوب', 'لابتوب', 'حاسب'],
    'حاسب':    ['كمبيوتر', 'حاسوب', 'لابتوب', 'حاسب'],
    // Jobs
    'وظيفة':  ['وظيفة', 'عمل', 'شغل', 'وظائف'],
    'عمل':    ['وظيفة', 'عمل', 'شغل', 'وظائف'],
    'شغل':    ['وظيفة', 'عمل', 'شغل'],
    // Clothes
    'ملابس':  ['ملابس', 'ثياب', 'ملبوسات', 'بضاعة'],
    'ثياب':   ['ملابس', 'ثياب', 'ملبوسات'],
    // Furniture
    'اثاث':   ['اثاث', 'أثاث', 'فرنتشر', 'موبليا', 'عفش'],
    'أثاث':   ['اثاث', 'أثاث', 'فرنتشر', 'موبليا', 'عفش'],
    'عفش':    ['اثاث', 'أثاث', 'موبليا', 'عفش'],
    'موبليا': ['اثاث', 'أثاث', 'موبليا', 'عفش'],
    // Animals / livestock
    'مواشي':  ['مواشي', 'حيوانات', 'ماشية', 'بهائم'],
    'ماشية':  ['مواشي', 'حيوانات', 'ماشية', 'بهائم'],
    // Bikes / motorcycles
    'دراجة':  ['دراجة', 'موتو', 'موتوسيكل', 'بايك'],
    'موتو':   ['دراجة', 'موتو', 'موتوسيكل', 'بايك'],
    'موتوسيكل': ['دراجة', 'موتو', 'موتوسيكل', 'بايك'],
  };

  /// Returns all synonyms for a given word (including the word itself).
  static List<String> getSynonyms(String word) {
    return _synonymGroups[word.toLowerCase()] ?? [word.toLowerCase()];
  }

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
    final baseWords = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2)
        .toSet()
        .toList();

    // Expand each word with its synonyms so synonym-based search works
    final expanded = <String>{};
    for (final word in baseWords) {
      expanded.add(word);
      expanded.addAll(getSynonyms(word));
    }
    return expanded.toList();
  }

  /// Expands a search query string into all unique keywords + their synonyms.
  static List<String> expandSearchQuery(String query) {
    final baseWords = query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2)
        .toSet()
        .toList();

    final expanded = <String>{};
    for (final word in baseWords) {
      expanded.add(word);
      expanded.addAll(getSynonyms(word));
    }
    return expanded.toList();
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
