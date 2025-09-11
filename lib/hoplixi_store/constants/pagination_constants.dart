/// Константы для пагинации
class PaginationConstants {
  /// Размер страницы по умолчанию
  static const int defaultPageSize = 20;

  /// Минимальный размер страницы
  static const int minPageSize = 1;

  /// Максимальный размер страницы
  static const int maxPageSize = 100;

  /// Размер страницы для автокомплита
  static const int autocompletePageSize = 10;

  /// Размер страницы для поиска
  static const int searchPageSize = 15;

  /// Размер страницы для популярных тегов
  static const int popularTagsPageSize = 25;

  /// Валидные поля для сортировки тегов
  static const List<String> validTagSortFields = [
    'name',
    'created_at',
    'modified_at',
    'type',
    'usage_count',
  ];

  /// Проверка корректности поля сортировки
  static bool isValidSortField(String? field) {
    return field != null && validTagSortFields.contains(field.toLowerCase());
  }

  /// Получение корректного поля сортировки
  static String getValidSortField(
    String? field, {
    String defaultField = 'name',
  }) {
    return isValidSortField(field) ? field!.toLowerCase() : defaultField;
  }
}

/// Перечисление направлений сортировки
enum SortDirection {
  asc,
  desc;

  /// Получение boolean значения для ascending
  bool get isAscending => this == SortDirection.asc;

  /// Получение направления из строки
  static SortDirection fromString(String? direction) {
    switch (direction?.toLowerCase()) {
      case 'desc':
      case 'descending':
        return SortDirection.desc;
      default:
        return SortDirection.asc;
    }
  }

  /// Получение строкового представления
  String get displayName {
    switch (this) {
      case SortDirection.asc:
        return 'По возрастанию';
      case SortDirection.desc:
        return 'По убыванию';
    }
  }
}

/// Класс для параметров пагинации
class PaginationParams {
  final int page;
  final int pageSize;
  final String sortField;
  final SortDirection sortDirection;

  const PaginationParams({
    this.page = 1,
    this.pageSize = PaginationConstants.defaultPageSize,
    this.sortField = 'name',
    this.sortDirection = SortDirection.asc,
  });

  /// Создание параметров из Map
  factory PaginationParams.fromMap(Map<String, dynamic> params) {
    return PaginationParams(
      page: (params['page'] as int?) ?? 1,
      pageSize:
          (params['pageSize'] as int?) ?? PaginationConstants.defaultPageSize,
      sortField: PaginationConstants.getValidSortField(
        params['sortField'] as String?,
      ),
      sortDirection: SortDirection.fromString(
        params['sortDirection'] as String?,
      ),
    );
  }

  /// Создание копии с изменениями
  PaginationParams copyWith({
    int? page,
    int? pageSize,
    String? sortField,
    SortDirection? sortDirection,
  }) {
    return PaginationParams(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortField: sortField ?? this.sortField,
      sortDirection: sortDirection ?? this.sortDirection,
    );
  }

  /// Получение валидных параметров
  PaginationParams get validated {
    return PaginationParams(
      page: page < 1 ? 1 : page,
      pageSize: pageSize.clamp(
        PaginationConstants.minPageSize,
        PaginationConstants.maxPageSize,
      ),
      sortField: PaginationConstants.getValidSortField(sortField),
      sortDirection: sortDirection,
    );
  }

  /// Получение offset для базы данных
  int get offset => (page - 1) * pageSize;

  /// Преобразование в Map
  Map<String, dynamic> toMap() {
    return {
      'page': page,
      'pageSize': pageSize,
      'sortField': sortField,
      'sortDirection': sortDirection.name,
    };
  }

  @override
  String toString() {
    return 'PaginationParams(page: $page, pageSize: $pageSize, sortField: $sortField, sortDirection: ${sortDirection.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaginationParams &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.sortField == sortField &&
        other.sortDirection == sortDirection;
  }

  @override
  int get hashCode {
    return Object.hash(page, pageSize, sortField, sortDirection);
  }
}
