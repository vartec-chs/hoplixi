import 'dart:io';
import '../box_db/simple_box_utils.dart';

/// Пример пользователя для демонстрации
class User {
  final String id;
  final String name;
  final String email;
  final int age;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'age': age,
    'createdAt': createdAt.toIso8601String(),
  };

  static User fromMap(Map<String, dynamic> map) => User(
    id: map['id'] as String,
    name: map['name'] as String,
    email: map['email'] as String,
    age: map['age'] as int,
    createdAt: DateTime.parse(map['createdAt'] as String),
  );
}

/// Пример использования простых коробок
Future<void> simpleBoxExample() async {
  // Создаем директорию для хранения
  final storageDir = Directory('./simple_storage');

  // Получаем менеджер коробок
  final manager = await getSimpleBoxManager(baseDirectory: storageDir);

  try {
    // Открываем зашифрованную коробку для пользователей
    final userBox = await manager.openBox<User>(
      boxName: 'users',
      fromMap: User.fromMap,
      toMap: (user) => user.toMap(),
      encrypted: true,
    );

    print('Коробка пользователей открыта');

    // Добавляем несколько пользователей
    final users = [
      User(
        id: 'user1',
        name: 'Иван Иванов',
        email: 'ivan@example.com',
        age: 30,
        createdAt: DateTime.now(),
      ),
      User(
        id: 'user2',
        name: 'Мария Петрова',
        email: 'maria@example.com',
        age: 25,
        createdAt: DateTime.now(),
      ),
      User(
        id: 'user3',
        name: 'Петр Сидоров',
        email: 'petr@example.com',
        age: 35,
        createdAt: DateTime.now(),
      ),
    ];

    // Сохраняем пользователей
    for (final user in users) {
      await userBox.put(user.id, user);
      print('Сохранен пользователь: ${user.name}');
    }

    // Получаем пользователя по ID
    final user1 = await userBox.get('user1');
    print('Найден пользователь: ${user1?.name}');

    // Поиск пользователей по возрасту
    print('\nПользователи старше 30 лет:');
    await for (final user in userBox.query((user) => user.age > 30)) {
      print('- ${user.name} (${user.age} лет)');
    }

    // Получаем статистику коробки
    final stats = await userBox.getStats();
    print('\nСтатистика коробки:');
    stats.forEach((key, value) => print('$key: $value'));

    // Компактификация
    print('\nВыполняем компактификацию...');
    await userBox.compact();

    // Удаляем пользователя
    await userBox.delete('user2');
    print('\nПользователь user2 удален');

    // Проверяем количество пользователей
    print('Количество пользователей: ${userBox.length}');

    // Получаем всех пользователей
    print('\nВсе оставшиеся пользователи:');
    await for (final user in userBox.getAll()) {
      print('- ${user.name} (${user.email})');
    }

    // Экспорт данных
    print('\nЭкспорт данных в JSON...');
    await exportBoxToJson(
      userBox,
      './users_export.json',
      (user) => user.toMap(),
    );

    // Статистика всех коробок
    print('\nСтатистика всех коробок:');
    final allStats = await manager.getAllBoxStats();
    allStats.forEach((boxName, stats) {
      print('$boxName: $stats');
    });

    // Создание бэкапа
    print('\nСоздание бэкапа коробки...');
    await manager.backupBox('users', './users_backup');
  } finally {
    // Закрываем все коробки
    await manager.shutdown();
    print('\nВсе коробки закрыты');
  }
}

/// Пример работы с незашифрованной коробкой
Future<void> plainBoxExample() async {
  final storageDir = Directory('./plain_storage');

  // Открываем незашифрованную коробку
  final configBox = await openSimpleBoxPlain<Map<String, dynamic>>(
    baseDir: storageDir,
    boxName: 'config',
    fromMap: (map) => map,
    toMap: (map) => map,
  );

  try {
    // Сохраняем настройки
    await configBox.put('app_settings', {
      'theme': 'dark',
      'language': 'ru',
      'notifications': true,
    });

    await configBox.put('user_preferences', {
      'auto_save': true,
      'show_tips': false,
    });

    print('Настройки сохранены');

    // Читаем настройки
    final appSettings = await configBox.get('app_settings');
    print('Настройки приложения: $appSettings');

    // Список всех ключей
    final keys = configBox.getAllKeys();
    print('Все ключи: $keys');
  } finally {
    await configBox.close();
    print('Коробка настроек закрыта');
  }
}

/// Главная функция для запуска примеров
Future<void> main() async {
  print('=== Пример работы с зашифрованными коробками ===');
  await simpleBoxExample();

  print('\n=== Пример работы с незашифрованными коробками ===');
  await plainBoxExample();

  print('\nВсе примеры выполнены!');
}
