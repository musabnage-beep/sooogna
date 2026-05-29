sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(String message, {Exception? exception}) = Failure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Exception? exception) failure,
  });

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => isSuccess ? (this as Success<T>).data : null;
  String? get errorMessage => isFailure ? (this as Failure<T>).message : null;
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Exception? exception) failure,
  }) =>
      success(data);
}

class Failure<T> extends Result<T> {
  final String message;
  final Exception? exception;

  const Failure(this.message, {this.exception});

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Exception? exception) failure,
  }) =>
      failure(message, exception);
}
