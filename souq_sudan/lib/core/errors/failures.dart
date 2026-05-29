abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'لا يوجد اتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى'])
      : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure([String message = 'ليس لديك صلاحية لهذا الإجراء'])
      : super(message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'العنصر غير موجود']) : super(message);
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
