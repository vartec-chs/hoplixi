import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';

/// Production-ready Result Pattern implementation using freezed sealed classes.
/// Covers all common scenarios for error and success handling.
///
/// Usage:
/// ```dart
/// Result<User, AppError> result = await userRepository.getUser(id);
/// result.when(
///   success: (user) => print('Got user: ${user.name}'),
///   failure: (error) => print('Error: ${error.message}'),
/// );
/// ```
@freezed
sealed class Result<T, E> with _$Result<T, E> {
  /// Success state with data
  const factory Result.success(T data) = Success<T, E>;

  /// Failure state with error
  const factory Result.failure(E error) = Failure<T, E>;

  const Result._();

  /// Returns true if this is a success result
  bool get isSuccess => this is Success<T, E>;

  /// Returns true if this is a failure result
  bool get isFailure => this is Failure<T, E>;

  /// Gets the success data or null
  T? get dataOrNull => switch (this) {
    Success(data: final data) => data,
    Failure() => null,
  };

  /// Gets the error or null
  E? get errorOrNull => switch (this) {
    Success() => null,
    Failure(error: final error) => error,
  };

  /// Gets the success data or throws the error
  T getOrThrow() => switch (this) {
    Success(data: final data) => data,
    Failure(error: final error) => throw error as Object,
  };

  /// Gets the success data or returns the default value
  T getOrElse(T Function(E error) defaultValue) => switch (this) {
    Success(data: final data) => data,
    Failure(error: final error) => defaultValue(error),
  };

  /// Gets the success data or returns the default value
  T getOrDefault(T defaultValue) => switch (this) {
    Success(data: final data) => data,
    Failure() => defaultValue,
  };

  /// Maps the success value to a new type
  Result<R, E> map<R>(R Function(T data) transform) => switch (this) {
    Success(data: final data) => Result.success(transform(data)),
    Failure(error: final error) => Result.failure(error),
  };

  /// Maps the error value to a new type
  Result<T, R> mapError<R>(R Function(E error) transform) => switch (this) {
    Success(data: final data) => Result.success(data),
    Failure(error: final error) => Result.failure(transform(error)),
  };

  /// Flat maps the success value to a new Result
  Result<R, E> flatMap<R>(Result<R, E> Function(T data) transform) =>
      switch (this) {
        Success(data: final data) => transform(data),
        Failure(error: final error) => Result.failure(error),
      };

  /// Flat maps the error value to a new Result
  Result<T, R> flatMapError<R>(Result<T, R> Function(E error) transform) =>
      switch (this) {
        Success(data: final data) => Result.success(data),
        Failure(error: final error) => transform(error),
      };

  /// Executes an action if this is a success
  Result<T, E> onSuccess(void Function(T data) action) {
    if (this case Success(data: final data)) {
      action(data);
    }
    return this;
  }

  /// Executes an action if this is a failure
  Result<T, E> onFailure(void Function(E error) action) {
    if (this case Failure(error: final error)) {
      action(error);
    }
    return this;
  }

  /// Folds the result into a single value
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(E error) onFailure,
  }) => switch (this) {
    Success(data: final data) => onSuccess(data),
    Failure(error: final error) => onFailure(error),
  };

  /// Recovers from failure by providing an alternative value
  Result<T, E> recover(T Function(E error) recovery) => switch (this) {
    Success() => this,
    Failure(error: final error) => Result.success(recovery(error)),
  };

  /// Recovers from failure by providing an alternative Result
  Result<T, E> recoverWith(Result<T, E> Function(E error) recovery) =>
      switch (this) {
        Success() => this,
        Failure(error: final error) => recovery(error),
      };

  /// Swaps success and failure
  Result<E, T> swap() => switch (this) {
    Success(data: final data) => Result.failure(data),
    Failure(error: final error) => Result.success(error),
  };

  /// Converts to nullable value (null for failure)
  T? toNullable() => dataOrNull;

  /// Converts to nullable error (null for success)
  E? toNullableError() => errorOrNull;
}

/// Extension for working with Future<Result>
extension FutureResultExtension<T, E> on Future<Result<T, E>> {
  /// Maps the success value asynchronously
  /// Accepts both sync and async transformers via FutureOr
  Future<Result<R, E>> mapAsync<R>(
    FutureOr<R> Function(T data) transform,
  ) async {
    final result = await this;
    return switch (result) {
      Success(data: final data) => Result.success(await transform(data)),
      Failure(error: final error) => Result.failure(error),
    };
  }

  /// Flat maps the success value asynchronously
  Future<Result<R, E>> flatMapAsync<R>(
    Future<Result<R, E>> Function(T data) transform,
  ) async {
    final result = await this;
    return switch (result) {
      Success(data: final data) => await transform(data),
      Failure(error: final error) => Result.failure(error),
    };
  }

  /// Maps the error value asynchronously
  /// Accepts both sync and async transformers via FutureOr
  Future<Result<T, R>> mapErrorAsync<R>(
    FutureOr<R> Function(E error) transform,
  ) async {
    final result = await this;
    return switch (result) {
      Success(data: final data) => Result.success(data),
      Failure(error: final error) => Result.failure(await transform(error)),
    };
  }

  /// Executes an action if this is a success
  Future<Result<T, E>> onSuccessAsync(
    Future<void> Function(T data) action,
  ) async {
    final result = await this;
    if (result case Success(data: final data)) {
      await action(data);
    }
    return result;
  }

  /// Executes an action if this is a failure
  Future<Result<T, E>> onFailureAsync(
    Future<void> Function(E error) action,
  ) async {
    final result = await this;
    if (result case Failure(error: final error)) {
      await action(error);
    }
    return result;
  }

  /// Recovers from failure asynchronously
  Future<Result<T, E>> recoverAsync(
    Future<T> Function(E error) recovery,
  ) async {
    final result = await this;
    return switch (result) {
      Success() => result,
      Failure(error: final error) => Result.success(await recovery(error)),
    };
  }

  /// Recovers from failure with alternative Result asynchronously
  Future<Result<T, E>> recoverWithAsync(
    Future<Result<T, E>> Function(E error) recovery,
  ) async {
    final result = await this;
    return switch (result) {
      Success() => result,
      Failure(error: final error) => await recovery(error),
    };
  }

  /// Gets the data or throws asynchronously
  Future<T> getOrThrowAsync() async {
    final result = await this;
    return result.getOrThrow();
  }

  /// Gets the data or returns default asynchronously
  Future<T> getOrElseAsync(T Function(E error) defaultValue) async {
    final result = await this;
    return result.getOrElse(defaultValue);
  }

  /// Gets the data or null asynchronously
  Future<T?> toNullableAsync() async {
    final result = await this;
    return result.toNullable();
  }
}

/// Extension for working with Iterable<Result>
extension IterableResultExtension<T, E> on Iterable<Result<T, E>> {
  /// Collects all successes, returns failure if any
  Result<List<T>, E> sequence() {
    final results = <T>[];
    for (final result in this) {
      switch (result) {
        case Success(data: final data):
          results.add(data);
        case Failure(error: final error):
          return Result.failure(error);
      }
    }
    return Result.success(results);
  }

  /// Collects all successes, ignoring failures
  List<T> collectSuccesses() {
    return whereType<Success<T, E>>().map((s) => s.data).toList();
  }

  /// Collects all failures, ignoring successes
  List<E> collectFailures() {
    return whereType<Failure<T, E>>().map((f) => f.error).toList();
  }

  /// Partitions into successes and failures
  ({List<T> successes, List<E> failures}) partition() {
    final successes = <T>[];
    final failures = <E>[];
    for (final result in this) {
      switch (result) {
        case Success(data: final data):
          successes.add(data);
        case Failure(error: final error):
          failures.add(error);
      }
    }
    return (successes: successes, failures: failures);
  }
}

/// Helper functions for creating Results
extension ResultConstructors on Result {
  /// Creates a Result from a nullable value
  static Result<T, E> fromNullable<T, E>(T? value, E Function() errorProvider) {
    return value != null
        ? Result.success(value)
        : Result.failure(errorProvider());
  }

  /// Catches exceptions and converts to Result
  static Result<T, E> tryCatch<T, E>(
    T Function() operation,
    E Function(Object error, StackTrace stackTrace) errorMapper,
  ) {
    try {
      return Result.success(operation());
    } catch (error, stackTrace) {
      return Result.failure(errorMapper(error, stackTrace));
    }
  }

  /// Catches exceptions asynchronously and converts to Result
  static Future<Result<T, E>> tryCatchAsync<T, E>(
    Future<T> Function() operation,
    E Function(Object error, StackTrace stackTrace) errorMapper,
  ) async {
    try {
      return Result.success(await operation());
    } catch (error, stackTrace) {
      return Result.failure(errorMapper(error, stackTrace));
    }
  }

  /// Combines two Results
  static Result<(T1, T2), E> combine2<T1, T2, E>(
    Result<T1, E> result1,
    Result<T2, E> result2,
  ) {
    return switch ((result1, result2)) {
      (Success(data: final d1), Success(data: final d2)) => Result.success((
        d1,
        d2,
      )),
      (Failure(error: final e), _) => Result.failure(e),
      (_, Failure(error: final e)) => Result.failure(e),
    };
  }

  /// Combines three Results
  static Result<(T1, T2, T3), E> combine3<T1, T2, T3, E>(
    Result<T1, E> result1,
    Result<T2, E> result2,
    Result<T3, E> result3,
  ) {
    return switch ((result1, result2, result3)) {
      (
        Success(data: final d1),
        Success(data: final d2),
        Success(data: final d3),
      ) =>
        Result.success((d1, d2, d3)),
      (Failure(error: final e), _, _) => Result.failure(e),
      (_, Failure(error: final e), _) => Result.failure(e),
      (_, _, Failure(error: final e)) => Result.failure(e),
    };
  }

  /// Combines four Results
  static Result<(T1, T2, T3, T4), E> combine4<T1, T2, T3, T4, E>(
    Result<T1, E> result1,
    Result<T2, E> result2,
    Result<T3, E> result3,
    Result<T4, E> result4,
  ) {
    return switch ((result1, result2, result3, result4)) {
      (
        Success(data: final d1),
        Success(data: final d2),
        Success(data: final d3),
        Success(data: final d4),
      ) =>
        Result.success((d1, d2, d3, d4)),
      (Failure(error: final e), _, _, _) => Result.failure(e),
      (_, Failure(error: final e), _, _) => Result.failure(e),
      (_, _, Failure(error: final e), _) => Result.failure(e),
      (_, _, _, Failure(error: final e)) => Result.failure(e),
    };
  }
}

/// Extension for converting from other types to Result
extension ToResultExtension<T> on T {
  /// Converts value to Success
  Result<T, E> toSuccess<E>() => Result.success(this);
}

extension ToResultErrorExtension<E> on E {
  /// Converts error to Failure
  Result<T, E> toFailure<T>() => Result.failure(this);
}

extension NullableToResultExtension<T> on T? {
  /// Converts nullable to Result
  Result<T, E> toResult<E>(E Function() errorProvider) {
    return this != null
        ? Result.success(this as T)
        : Result.failure(errorProvider());
  }
}
