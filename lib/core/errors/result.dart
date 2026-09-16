import 'app_error.dart';

/// A discriminated union representing success or failure.
/// Use [Result.ok] for success and [Result.err] for failure.
/// Avoids throwing exceptions across layer boundaries.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(AppError error) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T get value => (this as Ok<T>).value;
  AppError get error => (this as Err<T>).error;

  /// Map the success value, propagating errors unchanged.
  Result<U> map<U>(U Function(T) f) => switch (this) {
        Ok(:final value) => Result.ok(f(value)),
        Err(:final error) => Result.err(error),
      };

  /// Flat-map (chain) over a success value.
  Result<U> flatMap<U>(Result<U> Function(T) f) => switch (this) {
        Ok(:final value) => f(value),
        Err(:final error) => Result.err(error),
      };

  /// Execute [onOk] or [onErr] depending on the result.
  R fold<R>({
    required R Function(T) onOk,
    required R Function(AppError) onErr,
  }) =>
      switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final error) => onErr(error),
      };
}

final class Ok<T> extends Result<T> {
  @override
  final T value;
  const Ok(this.value);
}

final class Err<T> extends Result<T> {
  @override
  final AppError error;
  const Err(this.error);
}
