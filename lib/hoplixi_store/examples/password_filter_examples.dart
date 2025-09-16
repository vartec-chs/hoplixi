/// Примеры использования PasswordFilter для фильтрации паролей
library;

import '../models/password_filter.dart';
import '../services/password_service.dart';

class PasswordFilterExamples {
  final PasswordService passwordService;

  PasswordFilterExamples(this.passwordService);

  // ==================== ПРОСТЫЕ ПРИМЕРЫ ====================

  /// Поиск по тексту
  Future<void> searchByText() async {
    final filter = PasswordFilter.create(query: 'gmail', limit: 50);

    final result = await passwordService.getFilteredPasswords(filter);
    if (result.success) {
      print('Найдено ${result.data!.length} паролей с текстом "gmail"');
    }
  }

  /// Избранные пароли
  Future<void> getFavorites() async {
    final filter = PasswordFilter.create(
      isFavorite: true,
      sortField: PasswordSortField.modifiedAt,
      sortDirection: SortDirection.desc,
      limit: 100,
    );

    final result = await passwordService.getFilteredPasswords(filter);
    if (result.success) {
      print('Найдено ${result.data!.length} избранных паролей');
    }
  }

  /// Часто используемые пароли
  Future<void> getFrequentlyUsed() async {
    final filter = PasswordFilter.create(
      isFrequent: true,
      sortField: PasswordSortField.usedCount,
      sortDirection: SortDirection.desc,
      limit: 20,
    );

    final result = await passwordService.getFilteredPasswords(filter);
    if (result.success) {
      print('Найдено ${result.data!.length} часто используемых паролей');
    }
  }

  // ==================== ФИЛЬТРЫ ПО КАТЕГОРИЯМ ====================

  /// Пароли по одной категории
  Future<void> getPasswordsByCategory(String categoryId) async {
    final filter = PasswordFilter.create(
      categoryIds: [categoryId],
      isArchived: false, // исключить архивные
      sortField: PasswordSortField.name,
      sortDirection: SortDirection.asc,
    );

    final result = await passwordService.getFilteredPasswords(filter);
    if (result.success) {
      print('В категории найдено ${result.data!.length} паролей');
    }
  }

  /// Пароли по нескольким категориям
  Future<void> getPasswordsByCategories(List<String> categoryIds) async {
    final filter = PasswordFilter.create(
      categoryIds: categoryIds,
      categoriesMatch: MatchMode.any, // любая из категорий
      isFavorite: true, // только избранные
    );

    final result = await passwordService.getFilteredPasswords(filter);
    if (result.success) {
      print('В категориях найдено ${result.data!.length} избранных паролей');
    }
  }

  // ==================== ФИЛЬТРЫ ПО ТЕГАМ ====================

  /// Пароли с любым из тегов (OR)
  Future<void> getPasswordsByAnyTag(List<String> tagIds) async {
    final filter = PasswordFilter.create(
      tagIds: tagIds,
      tagsMatch: MatchMode.any, // любой из тегов
      sortField: PasswordSortField.lastAccessed,
      sortDirection: SortDirection.desc,
    );

    final result = await passwordService.getFilteredPasswords(filter);
    if (result.success) {
      print('С любым из тегов найдено ${result.data!.length} паролей');
    }
  }

  /// Пароли со всеми тегами (AND)
  Future<void> getPasswordsByAllTags(List<String> tagIds) async {
    final filter = PasswordFilter.create(
      tagIds: tagIds,
      tagsMatch: MatchMode.all, // все теги одновременно
      isArchived: false,
    );

    final result = await passwordService.getFilteredPasswords(filter);
    if (result.success) {
      print('Со всеми тегами найдено ${result.data!.length} паролей');
    }
  }

  // ==================== КОМПЛЕКСНЫЕ ФИЛЬТРЫ ====================

  /// Сложный поиск с множественными условиями
  Future<void> complexSearch() async {
    final filter = PasswordFilter.create(
      query: 'bank', // поиск по тексту
      categoryIds: ['work-category-id'], // только рабочая категория
      tagIds: ['important', 'secure'], // с тегами "важный" И "безопасный"
      tagsMatch: MatchMode.all,
      isFavorite: null, // не важно избранный или нет
      isArchived: false, // исключить архивные
      hasNotes: true, // только с заметками
      createdAfter: DateTime.now().subtract(
        Duration(days: 365),
      ), // за последний год
      isFrequent: null, // не важно часто используемый или нет
      sortField: PasswordSortField.modifiedAt,
      sortDirection: SortDirection.desc,
      limit: 50,
    );

    final result = await passwordService.getFilteredPasswords(filter);
    if (result.success) {
      print('По сложному фильтру найдено ${result.data!.length} паролей');
    }
  }

  /// Поиск недавно созданных паролей
  Future<void> getRecentPasswords() async {
    final filter = PasswordFilter.create(
      createdAfter: DateTime.now().subtract(Duration(days: 7)), // за неделю
      isArchived: false,
      sortField: PasswordSortField.createdAt,
      sortDirection: SortDirection.desc,
      limit: 20,
    );

    final result = await passwordService.getFilteredPasswords(filter);
    if (result.success) {
      print('За неделю создано ${result.data!.length} паролей');
    }
  }

  /// Поиск давно не используемых паролей
  Future<void> getStalePasswords() async {
    final filter = PasswordFilter.create(
      lastAccessedBefore: DateTime.now().subtract(
        Duration(days: 180),
      ), // не использовались 6 месяцев
      isArchived: false, // исключить уже архивные
      isFrequent: false, // исключить частые
      sortField: PasswordSortField.lastAccessed,
      sortDirection: SortDirection.asc,
      limit: 100,
    );

    final result = await passwordService.getFilteredPasswords(filter);
    if (result.success) {
      print('Давно не использованных паролей: ${result.data!.length}');
    }
  }

  // ==================== ПАГИНАЦИЯ ====================

  /// Пагинированный поиск
  Future<void> getPaginatedResults(int page, int pageSize) async {
    final filter = PasswordFilter.create(
      isArchived: false,
      sortField: PasswordSortField.name,
      sortDirection: SortDirection.asc,
      limit: pageSize,
      offset: page * pageSize,
    );

    final result = await passwordService.getFilteredPasswords(filter);
    final countResult = await passwordService.countFilteredPasswords(
      filter.copyWith(limit: null, offset: null),
    );

    if (result.success && countResult.success) {
      final total = countResult.data!;
      final totalPages = (total / pageSize).ceil();
      print('Страница ${page + 1} из $totalPages (всего паролей: $total)');
      print('На странице: ${result.data!.length} паролей');
    }
  }

  // ==================== STREAM ПРИМЕРЫ ====================

  /// Наблюдение за изменениями отфильтрованных паролей
  void watchFilteredPasswords() {
    final filter = PasswordFilter.create(isFavorite: true, isArchived: false);

    passwordService.watchFilteredPasswords(filter).listen((passwords) {
      print('Обновлено избранных паролей: ${passwords.length}');
    });
  }

  // ==================== УДОБНЫЕ МЕТОДЫ СЕРВИСА ====================

  /// Использование готовых методов сервиса
  Future<void> useServiceMethods() async {
    // Быстрый поиск
    await passwordService.quickSearchPasswords('google');

    print('Методы сервиса используются для удобной фильтрации!');
  }
}
