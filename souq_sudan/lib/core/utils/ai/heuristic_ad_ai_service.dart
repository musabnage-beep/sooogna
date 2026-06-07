import '../helpers.dart';
import 'ad_ai_service.dart';

/// Offline, deterministic ad assistant. Maps keywords to a category, tidies the
/// title, and fills a structured Arabic description template. No network, no
/// keys — always available so the "اقتراح" buttons work even on Spark/web.
class HeuristicAdAiService implements AdAiService {
  const HeuristicAdAiService();

  @override
  bool get isAvailable => true;

  /// Arabic + transliterated keyword hints per category id. First category with
  /// the most keyword hits wins.
  static const Map<String, List<String>> _categoryKeywords = {
    'cars': [
      'سيارة', 'عربية', 'تويوتا', 'هيونداي', 'كيا', 'مرسيدس', 'بي ام',
      'موديل', 'بانزين', 'ديزل', 'car', 'toyota'
    ],
    'real_estate': [
      'شقة', 'منزل', 'بيت', 'عقار', 'ارض', 'أرض', 'فيلا', 'عمارة', 'إيجار',
      'للايجار', 'للبيع', 'غرفة', 'دار'
    ],
    'mobiles': [
      'جوال', 'موبايل', 'هاتف', 'ايفون', 'آيفون', 'سامسونج', 'تابلت', 'iphone',
      'samsung', 'هواوي'
    ],
    'electronics': [
      'تلفزيون', 'شاشة', 'لابتوب', 'كمبيوتر', 'حاسوب', 'سماعة', 'كاميرا',
      'بلايستيشن', 'laptop', 'tv'
    ],
    'jobs': [
      'وظيفة', 'مطلوب', 'عمل', 'توظيف', 'دوام', 'راتب', 'موظف', 'خبرة'
    ],
    'services': [
      'خدمة', 'صيانة', 'تركيب', 'نقل', 'تنظيف', 'تصميم', 'برمجة'
    ],
    'livestock': [
      'خروف', 'بقرة', 'ماشية', 'مواشي', 'جمل', 'غنم', 'حيوان', 'دواجن'
    ],
    'furniture': [
      'كنبة', 'اثاث', 'أثاث', 'سرير', 'طاولة', 'كرسي', 'دولاب', 'مطبخ'
    ],
    'clothes': [
      'ملابس', 'فستان', 'حذاء', 'قميص', 'عباية', 'جلابية', 'حقيبة', 'بدلة'
    ],
  };

  @override
  Future<AdAiSuggestion> suggest({
    required String title,
    required String description,
    double? price,
    String? city,
  }) async {
    final cleanedTitle = _tidyTitle(title);
    final category = _matchCategory('$title $description');
    final desc = _buildDescription(
      title: cleanedTitle.isNotEmpty ? cleanedTitle : title,
      existing: description,
      price: price,
      city: city,
    );
    return AdAiSuggestion(
      title: cleanedTitle.isEmpty || cleanedTitle == title.trim()
          ? null
          : cleanedTitle,
      description: desc,
      categoryId: category,
    );
  }

  String _tidyTitle(String raw) {
    final collapsed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (collapsed.isEmpty) return '';
    // Strip trailing punctuation noise.
    return collapsed.replaceAll(RegExp(r'[.،,!؟?]+$'), '').trim();
  }

  String? _matchCategory(String text) {
    final keywords = Helpers.extractSearchKeywords(text).toSet();
    final lower = text.toLowerCase();
    String? best;
    var bestScore = 0;
    _categoryKeywords.forEach((id, hints) {
      var score = 0;
      for (final h in hints) {
        if (keywords.contains(h.toLowerCase()) || lower.contains(h)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        best = id;
      }
    });
    return bestScore > 0 ? best : null;
  }

  /// Produce a description only when the user's own text is too thin to be
  /// useful, so we never overwrite a good description.
  String? _buildDescription({
    required String title,
    required String existing,
    double? price,
    String? city,
  }) {
    if (existing.trim().length >= 40) return null;
    final lines = <String>[
      title.trim(),
      if (existing.trim().isNotEmpty) existing.trim(),
      if (price != null) 'السعر: ${price.toStringAsFixed(0)} ج.س',
      if (city != null && city.isNotEmpty) 'الموقع: $city',
      'للتواصل والاستفسار يرجى المراسلة.',
    ];
    return lines.where((l) => l.isNotEmpty).join('\n');
  }
}
