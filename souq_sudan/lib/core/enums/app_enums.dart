enum UserRole { user, admin }

enum AdStatus { active, pending, rejected, sold, expired, suspended }

enum MessageType { text, image }

enum ReportType { ad, user }

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.user:
        return 'user';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }
}

extension AdStatusExtension on AdStatus {
  String get value {
    switch (this) {
      case AdStatus.active:
        return 'active';
      case AdStatus.pending:
        return 'pending';
      case AdStatus.rejected:
        return 'rejected';
      case AdStatus.sold:
        return 'sold';
      case AdStatus.expired:
        return 'expired';
      case AdStatus.suspended:
        return 'suspended';
    }
  }

  String get arabicLabel {
    switch (this) {
      case AdStatus.active:
        return 'نشط';
      case AdStatus.pending:
        return 'قيد المراجعة';
      case AdStatus.rejected:
        return 'مرفوض';
      case AdStatus.sold:
        return 'تم البيع';
      case AdStatus.expired:
        return 'منتهي';
      case AdStatus.suspended:
        return 'معلق';
    }
  }

  static AdStatus fromString(String value) {
    switch (value) {
      case 'active':
        return AdStatus.active;
      case 'pending':
        return AdStatus.pending;
      case 'rejected':
        return AdStatus.rejected;
      case 'sold':
        return AdStatus.sold;
      case 'expired':
        return AdStatus.expired;
      case 'suspended':
        return AdStatus.suspended;
      default:
        return AdStatus.pending;
    }
  }
}

extension MessageTypeExtension on MessageType {
  String get value {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
    }
  }

  static MessageType fromString(String value) {
    switch (value) {
      case 'image':
        return MessageType.image;
      default:
        return MessageType.text;
    }
  }
}

extension ReportTypeExtension on ReportType {
  String get value {
    switch (this) {
      case ReportType.ad:
        return 'ad';
      case ReportType.user:
        return 'user';
    }
  }

  static ReportType fromString(String value) {
    switch (value) {
      case 'user':
        return ReportType.user;
      default:
        return ReportType.ad;
    }
  }
}
