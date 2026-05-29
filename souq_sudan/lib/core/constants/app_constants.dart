class AppConstants {
  AppConstants._();

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

  static const List<Map<String, String>> categories = [
    {'id': 'cars', 'name': 'سيارات', 'icon': 'directions_car'},
    {'id': 'real_estate', 'name': 'عقارات', 'icon': 'home_work'},
    {'id': 'mobiles', 'name': 'جوالات', 'icon': 'phone_android'},
    {'id': 'electronics', 'name': 'إلكترونيات', 'icon': 'devices'},
    {'id': 'jobs', 'name': 'وظائف', 'icon': 'work'},
    {'id': 'services', 'name': 'خدمات', 'icon': 'build'},
    {'id': 'livestock', 'name': 'مواشي', 'icon': 'pets'},
    {'id': 'furniture', 'name': 'أثاث', 'icon': 'chair'},
    {'id': 'clothes', 'name': 'ملابس', 'icon': 'checkroom'},
    {'id': 'other', 'name': 'أخرى', 'icon': 'more_horiz'},
  ];

  static const List<String> sudanStates = [
    'الخرطوم',
    'الجزيرة',
    'القضارف',
    'كسلا',
    'البحر الأحمر',
    'نهر النيل',
    'الشمالية',
    'شمال دارفور',
    'جنوب دارفور',
    'غرب دارفور',
    'وسط دارفور',
    'شرق دارفور',
    'شمال كردفان',
    'جنوب كردفان',
    'غرب كردفان',
    'النيل الأبيض',
    'النيل الأزرق',
    'سنار',
  ];
}
