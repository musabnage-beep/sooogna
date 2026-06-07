class Validators {
  Validators._();

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال رقم الهاتف';
    }
    final cleaned = value.replaceAll(' ', '').replaceAll('-', '');
    // Accept any international E.164 number (+country_code + digits)
    // OR Sudan local format (0XXXXXXXXX or 249XXXXXXXXX)
    final e164Regex = RegExp(r'^\+[1-9][0-9]{6,14}$');
    final sudanLocalRegex = RegExp(r'^0?9[0-9]{8}$'); // Sudan 09XXXXXXXX or 9XXXXXXXX
    final sudanLongRegex = RegExp(r'^249[0-9]{9}$');   // Without +
    if (!e164Regex.hasMatch(cleaned) &&
        !sudanLocalRegex.hasMatch(cleaned) &&
        !sudanLongRegex.hasMatch(cleaned)) {
      return 'يرجى إدخال رقم هاتف صحيح مع رمز الدولة (مثال: +249XXXXXXXXX)';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال الاسم';
    }
    if (value.trim().length < 2) {
      return 'يجب أن يكون الاسم حرفين على الأقل';
    }
    if (value.trim().length > 50) {
      return 'يجب أن لا يتجاوز الاسم 50 حرفاً';
    }
    return null;
  }

  static String? validateAdTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال عنوان الإعلان';
    }
    if (value.trim().length < 3) {
      return 'يجب أن يكون العنوان 3 أحرف على الأقل';
    }
    if (value.trim().length > 100) {
      return 'يجب أن لا يتجاوز العنوان 100 حرف';
    }
    return null;
  }

  static String? validateAdDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال وصف الإعلان';
    }
    if (value.trim().length < 10) {
      return 'يجب أن يكون الوصف 10 أحرف على الأقل';
    }
    if (value.trim().length > 2000) {
      return 'يجب أن لا يتجاوز الوصف 2000 حرف';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال السعر';
    }
    final price = double.tryParse(value.replaceAll(',', ''));
    if (price == null) {
      return 'يرجى إدخال سعر صحيح';
    }
    if (price < 0) {
      return 'يجب أن يكون السعر 0 أو أكثر';
    }
    if (price > 999999999) {
      return 'السعر كبير جداً';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال $fieldName';
    }
    return null;
  }

  static String? validateComment(String? value) {
    if (value != null && value.length > 500) {
      return 'يجب أن لا يتجاوز التعليق 500 حرف';
    }
    return null;
  }

  static String normalizePhone(String phone) {
    final cleaned = phone.replaceAll(' ', '').replaceAll('-', '');
    // Sudan local: 09XXXXXXXX → +24909XXXXXXXX  (09 prefix)
    if (cleaned.startsWith('09') && cleaned.length == 10) {
      return '+249${cleaned.substring(1)}';
    }
    // Sudan without country code: 0XXXXXXXXX → +249XXXXXXXXX
    if (cleaned.startsWith('0') && !cleaned.startsWith('00')) {
      return '+249${cleaned.substring(1)}';
    }
    // Sudan without +: 249XXXXXXXXX → +249XXXXXXXXX
    if (cleaned.startsWith('249') && !cleaned.startsWith('+')) {
      return '+$cleaned';
    }
    // International with +: leave as-is
    if (cleaned.startsWith('+')) {
      return cleaned;
    }
    return cleaned;
  }

  static String maskPhone(String phone) {
    if (phone.length < 8) return phone;
    final start = phone.substring(0, 4);
    final end = phone.substring(phone.length - 4);
    return '$start****$end';
  }
}
