class AppConstants {
  AppConstants._();

  /// When true, unauthenticated users can access the create-ad screen (demo only).
  static const bool isDemoMode = true;

  static const String appName = 'سوق السودان';
  static const String appVersion = '1.0.0';
  static const String supportWhatsAppNumber = '249900000000';
  static const String privacyPolicyUrl = 'https://souq-sudan.app/privacy';
  static const String termsOfServiceUrl = 'https://souq-sudan.app/terms';
  static const int adsPageSize = 20;
  static const int chatsPageSize = 30;
  static const int messagesPageSize = 50;
  static const int maxAdImages = 10;
  static const double maxImageSizeMB = 5.0;
  static const int maxImageSizeBytes = 5 * 1024 * 1024;
  static const int maxAdTitleLength = 100;
  static const int minAdTitleLength = 3;
  static const int maxAdDescriptionLength = 2000;
  static const int minAdDescriptionLength = 10;
  static const int maxNameLength = 50;
  static const int minNameLength = 2;
  static const int maxCommentLength = 500;
  static const int maxAdsPerDay = 10;
  static const int adPostCooldownMinutes = 2;
  static const int maxSearchTerms = 10;
  static const int recentSearchesMax = 10;
  static const String recentSearchesKey = 'recent_searches';
  static const String lastAdPostTimeKey = 'last_ad_post_time';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String themeModeKey = 'theme_mode';

  // Web base URL (used for share links + SEO canonical/sitemap URLs).
  static const String webBaseUrl = 'https://souq-sudan.app';

  // Pagination for new collections.
  static const int servicesPageSize = 20;
  static const int requestsPageSize = 20;
  static const int storeProductsPageSize = 20;
  static const int favoritesPageSize = 30;

  // Hard caps on otherwise-unbounded reads (cost/scale safety).
  static const int maxFavoritesRead = 300;
  static const int maxUserAdsRead = 200;
  static const int maxUserChatsScan = 200;
  static const int maxDeleteScan = 300;

  // Firestore collection names (centralized to avoid typos).
  static const String adsCollection = 'ads';
  static const String usersCollection = 'users';
  static const String reviewsCollection = 'reviews';
  static const String servicesCollection = 'services';
  static const String serviceRequestsCollection = 'serviceRequests';
  static const String serviceResponsesSubcollection = 'responses';
  static const String storesCollection = 'stores';
  static const String favoritesSubcollection = 'favorites';
  static const String verificationRequestsCollection = 'verificationRequests';
  static const String analyticsSubcollection = 'analytics';
  static const String analyticsSummaryDoc = 'summary';

  // Full administrative coverage of Sudan: all 18 states, each mapped to its
  // major cities / localities (محليات). Source of truth for every
  // state/city dropdown and the home location picker.
  static const Map<String, List<String>> sudanStatesCities = {
    'الخرطوم': [
      'الخرطوم', 'أم درمان', 'الخرطوم بحري', 'أمبدة', 'كرري',
      'جبل أولياء', 'شرق النيل', 'الكلاكلة', 'الحاج يوسف', 'الصحافة',
    ],
    'الجزيرة': [
      'ود مدني', 'الحصاحيصا', 'المناقل', 'الكاملين', 'رفاعة',
      'الحاج عبد الله', 'أبو قوتة', 'الماحص', 'القرشي', 'ود راوة',
    ],
    'القضارف': [
      'القضارف', 'الفاو', 'الفشقة', 'دوكة', 'القلابات',
      'الرهد', 'باسندة', 'قلع النحل',
    ],
    'كسلا': [
      'كسلا', 'خشم القربة', 'حلفا الجديدة', 'أروما', 'تلكوك',
      'ودالحليو', 'ساتيت', 'همشكوريب', 'نهر عطبرة',
    ],
    'البحر الأحمر': [
      'بورتسودان', 'سواكن', 'طوكر', 'سنكات', 'هيا',
      'دنقناب', 'جبيت', 'عقيق', 'حلايب',
    ],
    'نهر النيل': [
      'عطبرة', 'الدامر', 'شندي', 'بربر', 'أبو حمد',
      'المتمة', 'السليم', 'أبو دليق',
    ],
    'الشمالية': [
      'دنقلا', 'مروي', 'الدبة', 'وادي حلفا', 'كريمة',
      'أرقو', 'دلقو', 'البرقيق', 'الغابة',
    ],
    'شمال دارفور': [
      'الفاشر', 'كتم', 'مليط', 'كبكابية', 'اللعيت',
      'الطينة', 'أم كدادة', 'السرف', 'كرنوي',
    ],
    'جنوب دارفور': [
      'نيالا', 'عد الفرسان', 'كاس', 'بليل', 'تلس',
      'شعيرية', 'رهيد البردي', 'قريضة', 'دمسو', 'مرشنق',
    ],
    'شرق دارفور': [
      'الضعين', 'عديلة', 'أبو جابرة', 'أبو كارنكا', 'ياسين',
      'بحر العرب', 'شعيرية', 'الفردوس',
    ],
    'غرب دارفور': [
      'الجنينة', 'كرينك', 'بيضة', 'كلبس', 'سربا',
      'هبيلا', 'فوربرنقا', 'جبل مون',
    ],
    'وسط دارفور': [
      'زالنجي', 'وادي صالح', 'جبل مرة', 'أم دخن', 'بندسي',
      'مكجر', 'نيرتتي', 'روكورو', 'جلدو',
    ],
    'شمال كردفان': [
      'الأبيض', 'بارا', 'أم روابة', 'الرهد', 'سودري',
      'جبرة الشيخ', 'شيكان', 'غبيش', 'أم دم',
    ],
    'جنوب كردفان': [
      'كادقلي', 'الدلنج', 'أبو جبيهة', 'تلودي', 'رشاد',
      'هبيلا', 'كاودا', 'لقاوة', 'أبو كرشولا',
    ],
    'غرب كردفان': [
      'الفولة', 'بابنوسة', 'المجلد', 'النهود', 'أبيي',
      'السنط', 'كيلك', 'الميرم', 'وادي الهبانية',
    ],
    'النيل الأبيض': [
      'ربك', 'كوستي', 'الدويم', 'القطينة', 'تندلتي',
      'أم رمتة', 'الجبلين', 'السلام', 'الجزيرة أبا',
    ],
    'النيل الأزرق': [
      'الدمازين', 'الروصيرص', 'قيسان', 'الكرمك', 'باو',
      'التضامن', 'ود الماحي', 'قنيص',
    ],
    'سنار': [
      'سنار', 'سنجة', 'الدندر', 'أبو حجار', 'السوكي',
      'الدالي والمزموم', 'ود العباس', 'مايرنو',
    ],
  };

  // All states (administrative regions), ordered as in [sudanStatesCities].
  static List<String> get sudanStates => sudanStatesCities.keys.toList();

  // Cities for a given state (empty list if the state is unknown / null).
  static List<String> citiesForState(String? state) =>
      state == null ? const [] : (sudanStatesCities[state] ?? const []);

  // Flat, de-duplicated list of every city across all states — used by the
  // global city picker and the search filter.
  static List<String> get sudanCities {
    final seen = <String>{};
    final out = <String>[];
    for (final cities in sudanStatesCities.values) {
      for (final c in cities) {
        if (seen.add(c)) out.add(c);
      }
    }
    return out;
  }

  // Service professions (Feature 1) — id used in queries, name shown in Arabic.
  static const List<Map<String, String>> serviceProfessions = [
    {'id': 'programmer', 'name': 'مبرمج', 'icon': 'code'},
    {'id': 'graphic_designer', 'name': 'مصمم جرافيك', 'icon': 'brush'},
    {'id': 'makeup_artist', 'name': 'خبيرة تجميل', 'icon': 'face_retouching_natural'},
    {'id': 'photographer', 'name': 'مصور', 'icon': 'camera_alt'},
    {'id': 'electrician', 'name': 'كهربائي', 'icon': 'electrical_services'},
    {'id': 'plumber', 'name': 'سباك', 'icon': 'plumbing'},
    {'id': 'teacher', 'name': 'مدرس', 'icon': 'school'},
    {'id': 'translator', 'name': 'مترجم', 'icon': 'translate'},
    {'id': 'lawyer', 'name': 'محامي', 'icon': 'gavel'},
    {'id': 'mechanic', 'name': 'ميكانيكي', 'icon': 'build_circle'},
    {'id': 'freelancer', 'name': 'عمل حر', 'icon': 'work_outline'},
    {'id': 'other', 'name': 'أخرى', 'icon': 'more_horiz'},
  ];

  // Max images for a service portfolio / store products preview.
  static const int maxPortfolioImages = 10;
  static const int maxServiceRequestBudget = 1000000000;
  static const int maxResponseMessageLength = 1000;

  // Canonical category set. `id` matches the `category` field written to ad
  // docs (and the seed data); `icon` keys resolve via CategoryIcons.forName.
  static const List<Map<String, String>> categories = [
    {'id': 'cars', 'name': 'سيارات', 'icon': 'directions_car'},
    {'id': 'real_estate', 'name': 'عقارات', 'icon': 'home_rounded'},
    {'id': 'mobiles', 'name': 'جوالات', 'icon': 'smartphone_rounded'},
    {'id': 'electronics', 'name': 'إلكترونيات', 'icon': 'devices'},
    {'id': 'furniture', 'name': 'أثاث', 'icon': 'chair'},
    {'id': 'fashion', 'name': 'أزياء', 'icon': 'checkroom'},
    {'id': 'animals', 'name': 'حيوانات', 'icon': 'pets'},
    {'id': 'food', 'name': 'أطعمة', 'icon': 'restaurant_rounded'},
    {'id': 'services', 'name': 'خدمات', 'icon': 'handyman_rounded'},
    {'id': 'jobs', 'name': 'وظائف', 'icon': 'work'},
    {'id': 'other', 'name': 'أخرى', 'icon': 'more_horiz'},
  ];
}
