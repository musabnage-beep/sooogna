abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'لا يوجد اتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'ليس لديك صلاحية لهذا الإجراء']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'العنصر غير موجود']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class RateLimitFailure extends Failure {
  const RateLimitFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
