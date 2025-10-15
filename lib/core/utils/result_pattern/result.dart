// result.dart
import 'dart:async';

/// Универсальный Result<T, E>
/// E по умолчанию — Object (можно использовать Exception, String и т.д.)
abstract class Result<T, E extends Object> {
  const Result();

  bool get isSuccess;
  bool get isFailure => !isSuccess;

  /// Pattern-match
  R when<R>({
    required R Function(T value) success,
    required R Function(E error, StackTrace? stackTrace) failure,
  });

  /// Map успеха
  Result<R, E> map<R>(R Function(T value) f) {
    return when(
      success: (v) {
        try {
          return Success<R, E>(f(v));
        } catch (e, st) {
          return Failure<R, E>(e as E, st); // cast: caller chooses E type
        }
      },
      failure: (err, st) => Failure<R, E>(err, st),
    );
  }

  /// Map ошибки
  Result<T, F> mapError<F extends Object>(F Function(E error, StackTrace? st) f) {
    return when(
      success: (v) => Success<T, F>(v),
      failure: (err, st) {
        try {
          return Failure<T, F>(f(err, st), st);
        } catch (e, st2) {
          return Failure<T, F>(e as F, st2);
        }
      },
    );
  }

  /// FlatMap (sync)
  Result<R, E> flatMap<R>(Result<R, E> Function(T value) f) {
    return when(
      success: (v) {
        try {
          return f(v);
        } catch (e, st) {
          return Failure<R, E>(e as E, st);
        }
      },
      failure: (err, st) => Failure<R, E>(err, st),
    );
  }

  /// FlatMap (async)
  Future<Result<R, E>> asyncFlatMap<R>(Future<Result<R, E>> Function(T value) f) async {
    return await when(
      success: (v) async {
        try {
          return await f(v);
        } catch (e, st) {
          return Failure<R, E>(e as E, st);
        }
      },
      failure: (err, st) async => Failure<R, E>(err, st),
    );
  }

  /// Fold to value
  R fold<R>(R Function(T v) onSuccess, R Function(E err, StackTrace? st) onFailure) {
    return when(success: onSuccess, failure: onFailure);
  }

  /// Получить значение или дефолт
  T getOrElse(T Function() orElse) {
    return when(success: (v) => v, failure: (_, __) => orElse());
  }

  /// Получить значение или бросить ошибку (если failure)
  T getOrThrow() {
    return when(
      success: (v) => v,
      failure: (err, st) {
        if (err is Error) {
          // preserve stack
          throw err;
        } else {
          throw _ResultException(err, st);
        }
      },
    );
  }

  /// Преобразовать Future<T> в Future<Result<T, E>> с ловлей ошибок
  static Future<Result<T, E>> fromFuture<T, E extends Object>(Future<T> future) async {
    try {
      final v = await future;
      return Success<T, E>(v);
    } catch (e, st) {
      return Failure<T, E>(e as E, st);
    }
  }

  /// Выполнить синхронную функцию и поймать исключение
  static Result<T, Object> guardSync<T>(T Function() fn) {
    try {
      return Success<T, Object>(fn());
    } catch (e, st) {
      return Failure<T, Object>(e as Object, st);
    }
  }

  /// Выполнить асинхронную функцию и поймать исключение
  static Future<Result<T, Object>> guardAsync<T>(Future<T> Function() fn) async {
    try {
      final v = await fn();
      return Success<T, Object>(v);
    } catch (e, st) {
      return Failure<T, Object>(e as Object, st);
    }
  }

  /// Агрегировать список результатов — вернёт первый Failure или Success со списком значений.
  static Result<List<T>, E> sequence<T, E extends Object>(List<Result<T, E>> items) {
    final List<T> values = <T>[];
    for (final r in items) {
      if (r.isFailure) {
        return r.when(
          success: (_) => throw StateError('unreachable'),
          failure: (err, st) => Failure<List<T>, E>(err, st),
        );
      } else {
        final v = r.when(success: (v) => v, failure: (_, __) => throw StateError('unreachable'));
        values.add(v);
      }
    }
    return Success<List<T>, E>(values);
  }
}

class Success<T, E extends Object> extends Result<T, E> {
  final T value;
  const Success(this.value);

  @override
  bool get isSuccess => true;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(E error, StackTrace? stackTrace) failure,
  }) =>
      success(value);

  @override
  String toString() => 'Success($value)';
}

class Failure<T, E extends Object> extends Result<T, E> {
  final E error;
  final StackTrace? stackTrace;
  const Failure(this.error, [this.stackTrace]);

  @override
  bool get isSuccess => false;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(E error, StackTrace? stackTrace) failure,
  }) =>
      failure(error, stackTrace);

  @override
  String toString() => 'Failure($error, stackTrace: ${stackTrace ?? 'null'})';
}

class _ResultException implements Exception {
  final Object error;
  final StackTrace? stackTrace;
  _ResultException(this.error, this.stackTrace);

  @override
  String toString() => 'ResultException: $error\n${stackTrace ?? ''}';
}
