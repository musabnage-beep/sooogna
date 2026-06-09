import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLangPref = 'app_lang';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ar')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLangPref) ?? 'ar';
    state = Locale(code);
  }

  Future<void> setLocale(String langCode) async {
    state = Locale(langCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangPref, langCode);
  }

  void toggle() {
    setLocale(state.languageCode == 'ar' ? 'en' : 'ar');
  }
}

class S {
  static const Map<String, Map<String, String>> _t = {
    'app_name': {'ar': 'سوق السودان', 'en': 'Souq Sudan'},
    'home': {'ar': 'الرئيسية', 'en': 'Home'},
    'favorites': {'ar': 'المفضلة', 'en': 'Favorites'},
    'messages': {'ar': 'الرسائل', 'en': 'Messages'},
    'account': {'ar': 'حسابي', 'en': 'Account'},
    'search': {'ar': 'بحث', 'en': 'Search'},
    'search_hint': {'ar': 'ابحث في سوق السودان...', 'en': 'Search Souq Sudan...'},
    'all_sudan': {'ar': 'كل السودان', 'en': 'All Sudan'},
    'categories': {'ar': 'الأقسام', 'en': 'Categories'},
    'featured': {'ar': 'المميزة', 'en': 'Featured'},
    'latest_ads': {'ar': 'أحدث الإعلانات', 'en': 'Latest Ads'},
    'filter': {'ar': 'تصفية', 'en': 'Filter'},
    'filter_results': {'ar': 'تصفية النتائج', 'en': 'Filter Results'},
    'reset': {'ar': 'إعادة تعيين', 'en': 'Reset'},
    'apply': {'ar': 'تطبيق', 'en': 'Apply'},
    'category': {'ar': 'الفئة', 'en': 'Category'},
    'location': {'ar': 'الموقع', 'en': 'Location'},
    'city': {'ar': 'المدينة', 'en': 'City'},
    'select_state': {'ar': 'اختر الولاية', 'en': 'Select State'},
    'select_city': {'ar': 'اختر المدينة', 'en': 'Select City'},
    'all': {'ar': 'الكل', 'en': 'All'},
    'direct_owner_only': {'ar': 'المالك مباشرة فقط', 'en': 'Direct Owner Only'},
    'price_range': {'ar': 'نطاق السعر (ج.س)', 'en': 'Price Range (SDG)'},
    'min': {'ar': 'الحد الأدنى', 'en': 'Min'},
    'max': {'ar': 'الحد الأقصى', 'en': 'Max'},
    'sort_by': {'ar': 'الترتيب', 'en': 'Sort By'},
    'newest_first': {'ar': 'الأحدث أولاً', 'en': 'Newest First'},
    'oldest_first': {'ar': 'الأقدم أولاً', 'en': 'Oldest First'},
    'price_low_high': {'ar': 'السعر: الأقل أولاً', 'en': 'Price: Low to High'},
    'price_high_low': {'ar': 'السعر: الأعلى أولاً', 'en': 'Price: High to Low'},
    'create_ad': {'ar': 'إعلان جديد', 'en': 'New Ad'},
    'ad_title': {'ar': 'عنوان الإعلان *', 'en': 'Ad Title *'},
    'ad_title_hint': {'ar': 'مثال: سيارة تويوتا 2020 للبيع', 'en': 'Example: Toyota 2020 for sale'},
    'ad_desc': {'ar': 'وصف الإعلان *', 'en': 'Ad Description *'},
    'ad_desc_hint': {'ar': 'اكتب تفاصيل الإعلان...', 'en': 'Write ad details...'},
    'price': {'ar': 'السعر (ج.س) *', 'en': 'Price (SDG) *'},
    'price_hint': {'ar': '0 = مجاناً', 'en': '0 = Free'},
    'state': {'ar': 'الولاية *', 'en': 'State *'},
    'city_label': {'ar': 'المدينة / الحي *', 'en': 'City / Area *'},
    'city_hint': {'ar': 'مثال: الخرطوم بحري', 'en': 'Example: Khartoum North'},
    'phone': {'ar': 'رقم الهاتف *', 'en': 'Phone Number *'},
    'publish': {'ar': 'نشر الإعلان', 'en': 'Publish Ad'},
    'publishing': {'ar': 'جاري النشر...', 'en': 'Publishing...'},
    'ad_sent_review': {'ar': 'تم إرسال الإعلان للمراجعة', 'en': 'Ad submitted for review'},
    'add_image': {'ar': 'يرجى إضافة صورة واحدة على الأقل', 'en': 'Please add at least one image'},
    'select_category': {'ar': 'يرجى اختيار الفئة', 'en': 'Please select a category'},
    'select_state_val': {'ar': 'يرجى اختيار الولاية', 'en': 'Please select a state'},
    'login': {'ar': 'تسجيل الدخول', 'en': 'Login'},
    'register': {'ar': 'إنشاء حساب', 'en': 'Register'},
    'settings': {'ar': 'الإعدادات', 'en': 'Settings'},
    'language': {'ar': 'اللغة', 'en': 'Language'},
    'arabic': {'ar': 'العربية', 'en': 'Arabic'},
    'english': {'ar': 'الإنجليزية', 'en': 'English'},
    'notifications': {'ar': 'الإشعارات', 'en': 'Notifications'},
    'my_ads': {'ar': 'إعلاناتي', 'en': 'My Ads'},
    'edit_profile': {'ar': 'تعديل الملف الشخصي', 'en': 'Edit Profile'},
    'profile': {'ar': 'الملف الشخصي', 'en': 'Profile'},
    'chats': {'ar': 'المحادثات', 'en': 'Chats'},
    'view_all': {'ar': 'عرض الكل', 'en': 'View All'},
    'free': {'ar': 'مجاناً', 'en': 'Free'},
    'sdg': {'ar': 'ج.س', 'en': 'SDG'},
    'error': {'ar': 'خطأ', 'en': 'Error'},
    'path_not_found': {'ar': 'المسار غير موجود', 'en': 'Path not found'},
    'go_home': {'ar': 'الذهاب للرئيسية', 'en': 'Go Home'},
    'demo_mode': {'ar': '🔔 وضع الديمو — سيتم نشر الإعلان كزائر مؤقت', 'en': '🔔 Demo Mode — Ad will be posted as a guest'},
    'note_review': {'ar': 'ملاحظة: يتم مراجعة الإعلانات قبل النشر.', 'en': 'Note: Ads are reviewed before publishing.'},
    'details': {'ar': 'التفاصيل الإضافية', 'en': 'Additional Details'},
    'select': {'ar': 'اختر', 'en': 'Select'},
    // Categories
    'cat_cars': {'ar': 'سيارات', 'en': 'Cars'},
    'cat_real_estate': {'ar': 'عقارات', 'en': 'Real Estate'},
    'cat_mobiles': {'ar': 'موبايلات', 'en': 'Mobiles'},
    'cat_electronics': {'ar': 'إلكترونيات', 'en': 'Electronics'},
    'cat_furniture': {'ar': 'أثاث', 'en': 'Furniture'},
    'cat_fashion': {'ar': 'أزياء وموضة', 'en': 'Fashion'},
    'cat_animals': {'ar': 'حيوانات ومواشي', 'en': 'Animals'},
    'cat_food': {'ar': 'أغذية ومشروبات', 'en': 'Food & Drinks'},
    'cat_services': {'ar': 'خدمات', 'en': 'Services'},
    'cat_jobs': {'ar': 'وظائف', 'en': 'Jobs'},
    'cat_other': {'ar': 'أخرى', 'en': 'Other'},
  };

  static String tr(String key, String langCode) {
    final entry = _t[key];
    if (entry == null) return key;
    return entry[langCode] ?? entry['ar'] ?? key;
  }

  static String catName(String catId, String langCode) {
    return tr('cat_$catId', langCode);
  }
}
