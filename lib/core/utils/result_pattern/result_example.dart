import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/core/utils/result_pattern/result.dart';

part 'result_example.freezed.dart';

// Пример доменной ошибки
@freezed
sealed class AppError with _$AppError {
  const factory AppError.network(String message) = NetworkError;
  const factory AppError.notFound(String resource) = NotFoundError;
  const factory AppError.validation(String field, String message) =
      ValidationError;
  const factory AppError.permission(String action) = PermissionError;
  const factory AppError.unknown(String message) = UnknownError;

  const AppError._();

  String toUserMessage() => when(
    network: (msg) => 'Ошибка сети: $msg',
    notFound: (res) => '$res не найден',
    validation: (field, msg) => 'Ошибка в поле $field: $msg',
    permission: (action) => 'Нет прав для: $action',
    unknown: (msg) => 'Неизвестная ошибка: $msg',
  );
}

// Пример доменной модели
class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  static User guest() => User(id: 'guest', name: 'Guest', email: '');
}

// Пример сервиса
class UserService {
  Future<Result<User, AppError>> getUser(String id) async {
    return ResultConstructors.tryCatchAsync(
      () async {
        await Future.delayed(const Duration(milliseconds: 100));

        if (id.isEmpty) {
          throw AppError.validation('id', 'ID не может быть пустым');
        }

        if (id == 'not-found') {
          throw AppError.notFound('User');
        }

        return User(id: id, name: 'John Doe', email: 'john@example.com');
      },
      (error, stack) {
        if (error is AppError) return error;
        return AppError.unknown(error.toString());
      },
    );
  }

  Future<Result<List<User>, AppError>> getAllUsers() async {
    return ResultConstructors.tryCatchAsync(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      return [
        User(id: '1', name: 'User 1', email: 'user1@example.com'),
        User(id: '2', name: 'User 2', email: 'user2@example.com'),
        User(id: '3', name: 'User 3', email: 'user3@example.com'),
      ];
    }, (error, stack) => AppError.unknown(error.toString()));
  }
}

// Примеры использования
void main() async {
  final service = UserService();

  // Пример 1: Базовое использование с when
  print('=== Пример 1: Базовое использование ===');
  final result1 = await service.getUser('123');
  result1.when(
    success: (user) => print('✅ Успех: ${user.name}'),
    failure: (error) => print('❌ Ошибка: ${error.toUserMessage()}'),
  );

  // Пример 2: Обработка ошибки
  print('\n=== Пример 2: Обработка ошибки ===');
  final result2 = await service.getUser('not-found');
  result2.when(
    success: (user) => print('✅ Успех: ${user.name}'),
    failure: (error) => print('❌ Ошибка: ${error.toUserMessage()}'),
  );

  // Пример 3: Map трансформация
  print('\n=== Пример 3: Map трансформация ===');
  final result3 = await service.getUser('123');
  final nameResult = result3.map((user) => user.name);
  nameResult.when(
    success: (name) => print('✅ Имя: $name'),
    failure: (error) => print('❌ Ошибка: ${error.toUserMessage()}'),
  );

  // Пример 4: Railway-oriented programming
  print('\n=== Пример 4: Railway-oriented ===');
  final result4 = await service
      .getUser('123')
      .flatMapAsync((user) => validateUser(user))
      .mapAsync((user) => user.name.toUpperCase());
  result4.when(
    success: (name) => print('✅ Имя в верхнем регистре: $name'),
    failure: (error) => print('❌ Ошибка: ${error.toUserMessage()}'),
  );

  // Пример 5: getOrElse
  print('\n=== Пример 5: getOrElse ===');
  final result5 = await service.getUser('not-found');
  final user = result5.getOrElse((error) => User.guest());
  print('Пользователь: ${user.name}');

  // Пример 6: Fold
  print('\n=== Пример 6: Fold ===');
  final result6 = await service.getUser('123');
  final message = result6.fold(
    onSuccess: (user) => 'Добро пожаловать, ${user.name}!',
    onFailure: (error) => 'Не удалось загрузить: ${error.toUserMessage()}',
  );
  print(message);

  // Пример 7: Side effects (onSuccess/onFailure)
  print('\n=== Пример 7: Side effects ===');
  await service
      .getUser('123')
      .onSuccessAsync((user) async {
        print('📝 Логирование: пользователь получен ${user.id}');
      })
      .onFailureAsync((error) async {
        print('📝 Логирование ошибки: ${error.toUserMessage()}');
      });

  // Пример 8: Работа с коллекциями
  print('\n=== Пример 8: Коллекции ===');
  final results = await Future.wait([
    service.getUser('1'),
    service.getUser('2'),
    service.getUser('not-found'),
    service.getUser('3'),
  ]);

  final successes = results.collectSuccesses();
  final failures = results.collectFailures();
  print('✅ Успешно загружено: ${successes.length} пользователей');
  print('❌ Ошибок: ${failures.length}');

  // Пример 9: Комбинирование результатов
  print('\n=== Пример 9: Комбинирование ===');
  final user1Future = service.getUser('1');
  final user2Future = service.getUser('2');

  final combined = ResultConstructors.combine2(
    await user1Future,
    await user2Future,
  );

  combined.when(
    success: (data) {
      final (user1, user2) = data;
      print('✅ Получено два пользователя: ${user1.name} и ${user2.name}');
    },
    failure: (error) => print('❌ Ошибка: ${error.toUserMessage()}'),
  );

  // Пример 10: Recover
  print('\n=== Пример 10: Recover ===');
  final result10 = await service
      .getUser('not-found')
      .recoverAsync((error) async => User.guest());
  result10.when(
    success: (user) => print('✅ Пользователь (с fallback): ${user.name}'),
    failure: (error) => print('❌ Ошибка: ${error.toUserMessage()}'),
  );

  // Пример 11: Pattern matching с switch
  print('\n=== Пример 11: Switch expression ===');
  final result11 = await service.getUser('123');
  final display = switch (result11) {
    Success(data: final user) => '✅ ${user.name} (${user.email})',
    Failure(error: final error) => '❌ ${error.toUserMessage()}',
  };
  print(display);

  // Пример 12: Extension методы
  print('\n=== Пример 12: Extension методы ===');
  final user12 = User(id: '12', name: 'Test', email: 'test@test.com');
  final result12 = user12.toSuccess<AppError>();
  print('isSuccess: ${result12.isSuccess}');

  final error12 = AppError.notFound('Test');
  final result12err = error12.toFailure<User>();
  print('isFailure: ${result12err.isFailure}');
}

// Вспомогательная функция для примера
Future<Result<User, AppError>> validateUser(User user) async {
  if (user.email.isEmpty) {
    return Result.failure(
      AppError.validation('email', 'Email не может быть пустым'),
    );
  }
  return Result.success(user);
}
