/// Category-specific filter field definitions.
/// Each field: key, labelAr, labelEn, type ('select'|'number'), options (for select).
class CategoryFilters {
  CategoryFilters._();

  static const Map<String, List<Map<String, dynamic>>> fields = {
    'cars': [
      {
        'key': 'make',
        'labelAr': 'الماركة',
        'labelEn': 'Make',
        'type': 'select',
        'options': [
          'تويوتا', 'نيسان', 'هيونداي', 'كيا', 'هوندا', 'مازدا',
          'ميتسوبيشي', 'مرسيدس', 'بي ام دبليو', 'لكزس', 'شيفروليه',
          'فورد', 'سوزوكي', 'إيسوزو', 'لاندروفر', 'جيب', 'أخرى',
        ],
      },
      {
        'key': 'condition',
        'labelAr': 'الحالة',
        'labelEn': 'Condition',
        'type': 'select',
        'options': ['جديد', 'مستعمل'],
      },
      {
        'key': 'transmission',
        'labelAr': 'ناقل الحركة',
        'labelEn': 'Transmission',
        'type': 'select',
        'options': ['أوتوماتيك', 'يدوي'],
      },
      {
        'key': 'fuel_type',
        'labelAr': 'نوع الوقود',
        'labelEn': 'Fuel Type',
        'type': 'select',
        'options': ['بنزين', 'ديزل', 'هجين', 'كهرباء', 'غاز'],
      },
      {
        'key': 'color',
        'labelAr': 'اللون',
        'labelEn': 'Color',
        'type': 'select',
        'options': ['أبيض', 'أسود', 'فضي', 'رمادي', 'أحمر', 'أزرق', 'ذهبي', 'بني', 'أخضر', 'أخرى'],
      },
      {'key': 'year_min', 'labelAr': 'سنة الصنع من', 'labelEn': 'Year From', 'type': 'number'},
      {'key': 'year_max', 'labelAr': 'سنة الصنع إلى', 'labelEn': 'Year To', 'type': 'number'},
      {'key': 'mileage_max', 'labelAr': 'الممشى الأقصى (كم)', 'labelEn': 'Max Mileage (km)', 'type': 'number'},
    ],
    'real_estate': [
      {
        'key': 'property_type',
        'labelAr': 'نوع العقار',
        'labelEn': 'Property Type',
        'type': 'select',
        'options': ['شقة', 'فيلا', 'منزل', 'أرض', 'مستودع', 'مكتب', 'محل تجاري', 'فندق'],
      },
      {
        'key': 'purpose',
        'labelAr': 'الغرض',
        'labelEn': 'Purpose',
        'type': 'select',
        'options': ['للبيع', 'للإيجار', 'للإيجار اليومي'],
      },
      {
        'key': 'rooms',
        'labelAr': 'عدد الغرف',
        'labelEn': 'Bedrooms',
        'type': 'select',
        'options': ['1', '2', '3', '4', '5', '6+'],
      },
      {
        'key': 'bathrooms',
        'labelAr': 'عدد الحمامات',
        'labelEn': 'Bathrooms',
        'type': 'select',
        'options': ['1', '2', '3', '4+'],
      },
      {
        'key': 'furnished',
        'labelAr': 'التأثيث',
        'labelEn': 'Furnished',
        'type': 'select',
        'options': ['مفروشة', 'غير مفروشة', 'نصف مفروشة'],
      },
      {'key': 'area_min', 'labelAr': 'المساحة من (م²)', 'labelEn': 'Area From (m²)', 'type': 'number'},
      {'key': 'area_max', 'labelAr': 'المساحة إلى (م²)', 'labelEn': 'Area To (m²)', 'type': 'number'},
    ],
    'mobiles': [
      {
        'key': 'brand',
        'labelAr': 'الماركة',
        'labelEn': 'Brand',
        'type': 'select',
        'options': ['سامسونج', 'آبل', 'هواوي', 'شاومي', 'أوبو', 'فيفو', 'ون بلس', 'موتورولا', 'تيكنو', 'إيتيل', 'إنفنكس', 'نوكيا', 'أخرى'],
      },
      {
        'key': 'condition',
        'labelAr': 'الحالة',
        'labelEn': 'Condition',
        'type': 'select',
        'options': ['جديد', 'مستعمل - ممتاز', 'مستعمل - جيد', 'مستعمل - مقبول'],
      },
      {
        'key': 'storage',
        'labelAr': 'التخزين',
        'labelEn': 'Storage',
        'type': 'select',
        'options': ['16GB', '32GB', '64GB', '128GB', '256GB', '512GB', '1TB'],
      },
      {
        'key': 'ram',
        'labelAr': 'الرام',
        'labelEn': 'RAM',
        'type': 'select',
        'options': ['2GB', '3GB', '4GB', '6GB', '8GB', '12GB', '16GB'],
      },
    ],
    'electronics': [
      {
        'key': 'device_type',
        'labelAr': 'نوع الجهاز',
        'labelEn': 'Device Type',
        'type': 'select',
        'options': ['لابتوب', 'تابلت', 'شاشة', 'طابعة', 'كاميرا', 'تلفزيون', 'ثلاجة', 'غسالة', 'مكيف', 'جهاز صوت', 'أخرى'],
      },
      {
        'key': 'condition',
        'labelAr': 'الحالة',
        'labelEn': 'Condition',
        'type': 'select',
        'options': ['جديد', 'مستعمل - ممتاز', 'مستعمل - جيد', 'مستعمل - مقبول'],
      },
    ],
    'furniture': [
      {
        'key': 'condition',
        'labelAr': 'الحالة',
        'labelEn': 'Condition',
        'type': 'select',
        'options': ['جديد', 'مستعمل - ممتاز', 'مستعمل - جيد'],
      },
      {
        'key': 'material',
        'labelAr': 'الخامة',
        'labelEn': 'Material',
        'type': 'select',
        'options': ['خشب', 'معدن', 'بلاستيك', 'جلد', 'قماش', 'أخرى'],
      },
    ],
    'fashion': [
      {
        'key': 'condition',
        'labelAr': 'الحالة',
        'labelEn': 'Condition',
        'type': 'select',
        'options': ['جديد', 'مستعمل'],
      },
      {
        'key': 'gender',
        'labelAr': 'الجنس',
        'labelEn': 'Gender',
        'type': 'select',
        'options': ['رجالي', 'نسائي', 'أطفال', 'للجنسين'],
      },
      {
        'key': 'size',
        'labelAr': 'الحجم / المقاس',
        'labelEn': 'Size',
        'type': 'select',
        'options': ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL', 'أخرى'],
      },
    ],
    'animals': [
      {
        'key': 'animal_type',
        'labelAr': 'نوع الحيوان',
        'labelEn': 'Animal Type',
        'type': 'select',
        'options': ['أبقار', 'أغنام', 'جمال', 'دجاج', 'خيول', 'ماعز', 'حمام', 'كلاب', 'قطط', 'أخرى'],
      },
      {
        'key': 'age_stage',
        'labelAr': 'العمر',
        'labelEn': 'Age',
        'type': 'select',
        'options': ['صغير', 'بالغ', 'حامل'],
      },
    ],
    'jobs': [
      {
        'key': 'job_type',
        'labelAr': 'نوع الوظيفة',
        'labelEn': 'Job Type',
        'type': 'select',
        'options': ['دوام كامل', 'دوام جزئي', 'عن بعد', 'مؤقت', 'تدريب', 'عمل حر'],
      },
      {
        'key': 'sector',
        'labelAr': 'القطاع',
        'labelEn': 'Sector',
        'type': 'select',
        'options': ['تقنية', 'طب وصحة', 'تعليم', 'هندسة', 'مبيعات', 'محاسبة ومالية', 'قانون', 'إدارة', 'إعلام', 'فنون', 'خدمات', 'أخرى'],
      },
      {
        'key': 'experience',
        'labelAr': 'الخبرة المطلوبة',
        'labelEn': 'Experience Required',
        'type': 'select',
        'options': ['بدون خبرة', 'أقل من سنة', '1-3 سنوات', '3-5 سنوات', '5-10 سنوات', '10+ سنوات'],
      },
    ],
    'services': [
      {
        'key': 'service_type',
        'labelAr': 'نوع الخدمة',
        'labelEn': 'Service Type',
        'type': 'select',
        'options': ['صيانة', 'نقل وشحن', 'تدريس', 'تصميم', 'برمجة', 'تنظيف', 'طبخ', 'حراسة', 'سباكة', 'كهرباء', 'دهان', 'أخرى'],
      },
    ],
  };

  /// Returns fields for a given category id, or empty list.
  static List<Map<String, dynamic>> forCategory(String? categoryId) {
    if (categoryId == null) return [];
    return fields[categoryId] ?? [];
  }

  static String labelFor(Map<String, dynamic> field, String langCode) {
    return langCode == 'en'
        ? (field['labelEn'] as String? ?? field['labelAr'] as String)
        : (field['labelAr'] as String);
  }
}
