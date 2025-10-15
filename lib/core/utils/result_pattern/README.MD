

```dart
// Пример приложения-уровня ошибки:
class AppError {
  final String message;
  final int? code;
  AppError(this.message, {this.code});
  @override
  String toString() => 'AppError(code: $code, message: $message)';
}

// Асинхронный вызов:
Future<Result<String, AppError>> fetchName() async {
  return Result.fromFuture<String, AppError>(Future<String>.delayed(
    Duration(milliseconds: 100),
    () => throw AppError('Network failed', code: 502),
  ));
}

// Вызов и обработка:
void example() async {
  final r = await fetchName();
  r.when(
    success: (name) => print('got: $name'),
    failure: (err, st) {
      // логируем ошибку с трассировкой
      print('fetchName failed: $err');
      if (st != null) print(st);
    },
  );

  // Чейн:
  final result = await fetchName()
      .then((r) => r.asyncFlatMap<String>((name) async {
            // some follow-up async operation that may also return a Result
            return Success('processed: $name');
          }))
      .catchError((e, st) => Failure<String, AppError>(AppError(e.toString())));

  // Получить значение или дефолт:
  final value = result.getOrElse(() => 'default');
  print(value);
}

// Агрегация:
final listResults = [
  Success<int, AppError>(1),
  Success<int, AppError>(2),
  // Failure<int, AppError>(AppError('bad')),
];
final aggregated = Result.sequence<int, AppError>(listResults);
aggregated.when(
  success: (vals) => print(vals),
  failure: (err, st) => print('first failure: $err'),
);
```