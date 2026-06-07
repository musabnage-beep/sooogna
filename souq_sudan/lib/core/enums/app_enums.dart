enum UserRole { user, admin }

enum AdStatus { active, pending, rejected, sold, expired, suspended }

enum MessageType { text, image }

enum ReportType { ad, user }

/// Verification tier for a user account (Feature 3).
enum VerifiedStatus { unverified, verified, premium }

/// Who is posting the ad (Feature 6) — helps buyers avoid brokers.
enum OwnerType { owner, broker, company }

/// Lifecycle of a customer service request (Feature 2).
enum RequestStatus { open, inProgress, closed }

/// Target of a review (Feature 4) — keeps reviews backward compatible.
enum ReviewTarget { user, service, store }

/// Status of an identity verification request (Feature 3).
enum VerificationRequestStatus { pending, approved, rejected }

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

extension VerifiedStatusExtension on VerifiedStatus {
  String get value {
    switch (this) {
      case VerifiedStatus.unverified:
        return 'unverified';
      case VerifiedStatus.verified:
        return 'verified';
      case VerifiedStatus.premium:
        return 'premium';
    }
  }

  String get arabicLabel {
    switch (this) {
      case VerifiedStatus.unverified:
        return 'غير موثق';
      case VerifiedStatus.verified:
        return 'موثق';
      case VerifiedStatus.premium:
        return 'موثق مميز';
    }
  }

  bool get isVerified => this != VerifiedStatus.unverified;

  static VerifiedStatus fromString(String? value) {
    switch (value) {
      case 'verified':
        return VerifiedStatus.verified;
      case 'premium':
        return VerifiedStatus.premium;
      default:
        return VerifiedStatus.unverified;
    }
  }
}

extension OwnerTypeExtension on OwnerType {
  String get value {
    switch (this) {
      case OwnerType.owner:
        return 'owner';
      case OwnerType.broker:
        return 'broker';
      case OwnerType.company:
        return 'company';
    }
  }

  String get arabicLabel {
    switch (this) {
      case OwnerType.owner:
        return 'المالك مباشرة';
      case OwnerType.broker:
        return 'وسيط';
      case OwnerType.company:
        return 'شركة';
    }
  }

  static OwnerType fromString(String? value) {
    switch (value) {
      case 'broker':
        return OwnerType.broker;
      case 'company':
        return OwnerType.company;
      default:
        return OwnerType.owner;
    }
  }
}

extension RequestStatusExtension on RequestStatus {
  String get value {
    switch (this) {
      case RequestStatus.open:
        return 'open';
      case RequestStatus.inProgress:
        return 'in_progress';
      case RequestStatus.closed:
        return 'closed';
    }
  }

  String get arabicLabel {
    switch (this) {
      case RequestStatus.open:
        return 'مفتوح';
      case RequestStatus.inProgress:
        return 'قيد التنفيذ';
      case RequestStatus.closed:
        return 'مغلق';
    }
  }

  static RequestStatus fromString(String? value) {
    switch (value) {
      case 'in_progress':
        return RequestStatus.inProgress;
      case 'closed':
        return RequestStatus.closed;
      default:
        return RequestStatus.open;
    }
  }
}

extension ReviewTargetExtension on ReviewTarget {
  String get value {
    switch (this) {
      case ReviewTarget.user:
        return 'user';
      case ReviewTarget.service:
        return 'service';
      case ReviewTarget.store:
        return 'store';
    }
  }

  static ReviewTarget fromString(String? value) {
    switch (value) {
      case 'service':
        return ReviewTarget.service;
      case 'store':
        return ReviewTarget.store;
      default:
        return ReviewTarget.user;
    }
  }
}

extension VerificationRequestStatusExtension on VerificationRequestStatus {
  String get value {
    switch (this) {
      case VerificationRequestStatus.pending:
        return 'pending';
      case VerificationRequestStatus.approved:
        return 'approved';
      case VerificationRequestStatus.rejected:
        return 'rejected';
    }
  }

  String get arabicLabel {
    switch (this) {
      case VerificationRequestStatus.pending:
        return 'قيد المراجعة';
      case VerificationRequestStatus.approved:
        return 'مقبول';
      case VerificationRequestStatus.rejected:
        return 'مرفوض';
    }
  }

  static VerificationRequestStatus fromString(String? value) {
    switch (value) {
      case 'approved':
        return VerificationRequestStatus.approved;
      case 'rejected':
        return VerificationRequestStatus.rejected;
      default:
        return VerificationRequestStatus.pending;
    }
  }
}
