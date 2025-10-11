import 'dart:convert';
import 'dart:io';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/services/service_results.dart';

class JsonParserForMigration {
  /// Парсит JSON из файла и возвращает списки паролей и категорий
  ServiceResult<Map<String, List<dynamic>>> parseFromFile(String filePath) {
    try {
      // Проверяем, существует ли файл
      final file = File(filePath);
      if (!file.existsSync()) {
        return ServiceResult.error('Файл не найден: $filePath');
      }

      // Читаем содержимое файла
      final jsonString = file.readAsStringSync();

      // Парсим JSON
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Проверяем наличие ключей
      if (!data.containsKey('passwords') || !data.containsKey('categories')) {
        return ServiceResult.error(
          'Неверная структура JSON: отсутствуют ключи "passwords" или "categories"',
        );
      }

      // Парсим пароли
      final passwordsJson = data['passwords'] as List<dynamic>;
      final passwords = <CreatePasswordDto>[];
      for (final passwordJson in passwordsJson) {
        try {
          passwords.add(
            CreatePasswordDto.fromJson(passwordJson as Map<String, dynamic>),
          );
        } catch (e) {
          return ServiceResult.error('Ошибка парсинга пароля: $e');
        }
      }

      // Парсим категории
      final categoriesJson = data['categories'] as List<dynamic>;
      final categories = <CreateCategoryForMigrationDto>[];
      for (final categoryJson in categoriesJson) {
        try {
          categories.add(
            CreateCategoryForMigrationDto.fromJson(
              categoryJson as Map<String, dynamic>,
            ),
          );
        } catch (e) {
          return ServiceResult.error('Ошибка парсинга категории: $e');
        }
      }

      // Возвращаем успешный результат
      return ServiceResult.success(
        data: {'passwords': passwords, 'categories': categories},
        message: 'Парсинг выполнен успешно',
      );
    } catch (e) {
      return ServiceResult.error('Ошибка при парсинге файла: $e');
    }
  }
}
