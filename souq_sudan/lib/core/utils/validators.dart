class Validators {
  Validators._();

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال رقم الهاتف';
    }
    final cleaned = value.replaceAll(' ', '').replaceAll('-', '');
    final phoneRegex = RegExp(r'^\+?249[0-9]{9}$');
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'يرجى إدخال رقم هاتف سوداني صحيح (+249XXXXXXXXX)';
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
    if (cleaned.startsWith('0')) {
      return '+249${cleaned.substring(1)}';
    }
    if (cleaned.startsWith('249') && !cleaned.startsWith('+')) {
      return '+$cleaned';
    }
    return cleaned;
  }

  static String maskPhone(String phone) {
    if (phone.length < 8) return phone;
    final start = phone.substring(0, 4);
    final end = phone.substring(phone.length - 4);
    return '${start}****$end';
  }
}
