import 'dart:convert';
import 'dart:io';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:uuid/uuid.dart';

class JsonGeneratorForMigration {
  final _uuid = const Uuid();

  /// Генерирует заданное количество паролей и категорий, сериализует в JSON и сохраняет в файл
  void generateAndSave({
    required int passwordCount,
    required int categoryCount,
    required String filePath,
  }) {
    // Сначала генерируем категории с ID
    final categories = _generateCategories(categoryCount);

    // Затем генерируем пароли, привязывая их к категориям
    final passwords = _generatePasswords(passwordCount, categories);

    final data = {
      'categories': categories.map((c) => c.toJson()).toList(),
      'passwords': passwords.map((p) => p.toJson()).toList(),
    };

    // Красивое форматирование JSON с отступами
    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(data);
    File(filePath).writeAsStringSync(jsonString);
  }

  List<CreatePasswordDto> _generatePasswords(
    int count,
    List<CreateCategoryForMigrationDto> categories,
  ) {
    final passwords = <CreatePasswordDto>[];
    for (int i = 0; i < count; i++) {
      // Равномерно распределяем пароли по категориям
      final categoryId = categories.isNotEmpty
          ? categories[i % categories.length].migrationId
          : null;

      passwords.add(
        CreatePasswordDto(
          name: 'Password ${i + 1}',
          description: '',
          password: '',
          url: '',
          notes: '',
          login: '',
          email: '',
          categoryId: categoryId,
          isFavorite: false,
        ),
      );
    }
    return passwords;
  }

  List<CreateCategoryForMigrationDto> _generateCategories(int count) {
    final categories = <CreateCategoryForMigrationDto>[];
    for (int i = 0; i < count; i++) {
      final id = _uuid.v4();
      categories.add(
        CreateCategoryForMigrationDto(
          migrationId: id,
          name: 'Category ${i + 1}',
          description: 'Description for category ${i + 1}',
          iconId: null,
          color: 'FFFFFF',
          type: CategoryType.password,
        ),
      );
    }
    return categories;
  }
}
