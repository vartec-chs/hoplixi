import 'storage_manager.dart';

/// Менеджер индексов для быстрого поиска записей
class IndexManager {
  final StorageManager _storage;
  Map<String, IndexEntry> _index = {};
  Set<int> _deletedLines = {}; // Номера удалённых/устаревших строк

  IndexManager(this._storage);

  /// Загрузить индекс из файла
  Future<void> load() async {
    final indexData = await _storage.readIndex();
    _index = indexData.map((key, value) {
      final data = value as Map<String, dynamic>;
      return MapEntry(key, IndexEntry.fromJson(data));
    });

    // Загрузить список удалённых строк из meta
    final meta = await _storage.readMeta();
    final deletedLinesList = meta['deleted_lines'] as List<dynamic>?;
    if (deletedLinesList != null) {
      _deletedLines = deletedLinesList.map((e) => e as int).toSet();
    } else {
      _deletedLines = {};
    }
  }

  /// Сохранить индекс в файл
  Future<void> save() async {
    final indexData = _index.map((key, value) => MapEntry(key, value.toJson()));
    await _storage.writeIndex(indexData);

    // Сохранить список удалённых строк в meta
    await _storage.updateMeta({'deleted_lines': _deletedLines.toList()});
  }

  /// Добавить запись в индекс
  void add(String id, int lineNumber) {
    _index[id] = IndexEntry(line: lineNumber, deleted: false);
  }

  /// Получить информацию о записи
  IndexEntry? get(String id) {
    return _index[id];
  }

  /// Пометить запись как удаленную
  void markDeleted(String id) {
    final entry = _index[id];
    if (entry != null) {
      // Добавить строку в список удалённых
      _deletedLines.add(entry.line);
      _index[id] = IndexEntry(
        line: entry.line,
        deleted: true,
        timestamp: entry.timestamp,
      );
    }
  }

  /// Обновить позицию записи
  void update(String id, int newLineNumber) {
    final oldEntry = _index[id];
    if (oldEntry != null) {
      // Старая строка становится мусором
      _deletedLines.add(oldEntry.line);
    }
    _index[id] = IndexEntry(line: newLineNumber, deleted: false);
  }

  /// Проверить существование записи
  bool exists(String id) {
    final entry = _index[id];
    return entry != null && !entry.deleted;
  }

  /// Получить все ID
  List<String> getAllIds() {
    return _index.entries
        .where((e) => !e.value.deleted)
        .map((e) => e.key)
        .toList();
  }

  /// Получить количество активных записей
  int get count {
    return _index.values.where((e) => !e.deleted).length;
  }

  /// Получить количество удаленных записей
  int get deletedCount {
    return _index.values.where((e) => e.deleted).length;
  }

  /// Получить количество удалённых строк (мусора)
  int get garbageCount {
    return _deletedLines.length;
  }

  /// Проверить, нужна ли компактификация
  ///
  /// Проверяет количество удалённых/устаревших строк.
  /// Если количество >= threshold, то нужна компактификация.
  ///
  /// [threshold] - количество удалённых строк для запуска компактификации (по умолчанию 10)
  bool needsCompaction({int threshold = 10}) {
    return _deletedLines.length >= threshold;
  }

  /// Получить копию индекса для компактификации
  Map<String, dynamic> toMap() {
    return _index.map((key, value) => MapEntry(key, value.toJson()));
  }

  /// Очистить индекс
  Future<void> clear() async {
    _index.clear();
    _deletedLines.clear();
    // Сохранить пустой список в meta
    await _storage.updateMeta({'deleted_lines': []});
  }

  /// Получить ID записей, отсортированных по времени (новые первыми)
  List<String> getIdsSortedByTime({bool ascending = false}) {
    final entries = _index.entries.where((e) => !e.value.deleted).toList();

    entries.sort((a, b) {
      final comparison = a.value.timestamp.compareTo(b.value.timestamp);
      return ascending ? comparison : -comparison;
    });

    return entries.map((e) => e.key).toList();
  }

  /// Получить ID недавних записей
  ///
  /// [limit] - максимальное количество записей (по умолчанию 10)
  /// [since] - получить записи после указанного времени (опционально)
  List<String> getRecentIds({int limit = 10, DateTime? since}) {
    var entries = _index.entries.where((e) => !e.value.deleted).toList();

    // Фильтровать по времени если указано
    if (since != null) {
      entries = entries.where((e) => e.value.timestamp.isAfter(since)).toList();
    }

    // Сортировать по времени (новые первыми)
    entries.sort((a, b) => b.value.timestamp.compareTo(a.value.timestamp));

    // Ограничить количество
    if (entries.length > limit) {
      entries = entries.sublist(0, limit);
    }

    return entries.map((e) => e.key).toList();
  }

  /// Получить ID записей за указанный период
  ///
  /// [from] - начало периода
  /// [to] - конец периода (по умолчанию текущее время)
  List<String> getIdsByTimeRange({required DateTime from, DateTime? to}) {
    final endTime = to ?? DateTime.now();

    final entries = _index.entries
        .where(
          (e) =>
              !e.value.deleted &&
              e.value.timestamp.isAfter(from) &&
              e.value.timestamp.isBefore(endTime),
        )
        .toList();

    // Сортировать по времени (новые первыми)
    entries.sort((a, b) => b.value.timestamp.compareTo(a.value.timestamp));

    return entries.map((e) => e.key).toList();
  }

  /// Получить временную метку записи
  DateTime? getTimestamp(String id) {
    return _index[id]?.timestamp;
  }
}

/// Запись в индексе
class IndexEntry {
  final int line;
  final bool deleted;
  final DateTime timestamp;

  IndexEntry({required this.line, required this.deleted, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'line': line,
    'deleted': deleted,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory IndexEntry.fromJson(Map<String, dynamic> json) => IndexEntry(
    line: json['line'] as int,
    deleted: json['deleted'] as bool? ?? false,
    timestamp: json['timestamp'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
        : DateTime.now(),
  );
}
