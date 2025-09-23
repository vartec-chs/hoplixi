import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/universal_filter/universal_filter_barrel.dart';

/// Универсальный компонент списка записей с поддержкой фильтрации и пагинации
class UniversalRecordsList extends ConsumerStatefulWidget {
  /// Callback для обработки нажатия на запись
  final void Function(dynamic record)? onRecordTap;

  /// Callback для обработки длинного нажатия на запись
  final void Function(dynamic record)? onRecordLongPress;

  /// Пользовательский builder для элемента списка
  final Widget Function(BuildContext context, dynamic record, int index)?
  itemBuilder;

  /// Показывать ли индикатор загрузки
  final bool showLoadingIndicator;

  /// Сообщение при отсутствии записей
  final String? emptyMessage;

  /// Виджет, отображаемый при отсутствии записей
  final Widget? emptyWidget;

  /// Включить ли pull-to-refresh
  final bool enableRefresh;

  /// Callback для обновления данных
  final Future<void> Function()? onRefresh;

  /// Количество записей для пагинации
  final int pageSize;

  const UniversalRecordsList({
    super.key,
    this.onRecordTap,
    this.onRecordLongPress,
    this.itemBuilder,
    this.showLoadingIndicator = true,
    this.emptyMessage,
    this.emptyWidget,
    this.enableRefresh = true,
    this.onRefresh,
    this.pageSize = 20,
  });

  @override
  ConsumerState<UniversalRecordsList> createState() =>
      _UniversalRecordsListState();
}

class _UniversalRecordsListState extends ConsumerState<UniversalRecordsList> {
  final ScrollController _scrollController = ScrollController();
  final List<dynamic> _records = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Загружаем первую страницу
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecords(reset: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMoreData) {
        _loadMoreRecords();
      }
    }
  }

  Future<void> _loadRecords({bool reset = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        _records.clear();
        _currentPage = 0;
        _hasMoreData = true;
      }
    });

    try {
      final entityType = ref.read(currentEntityTypeProvider);
      final filter = ref.read(currentUniversalFilterProvider);

      // Здесь должна быть логика загрузки данных в зависимости от типа сущности
      final newRecords = await _fetchRecordsForType(
        entityType,
        filter,
        _currentPage,
      );

      setState(() {
        if (reset) {
          _records.clear();
        }
        _records.addAll(newRecords);
        _hasMoreData = newRecords.length >= widget.pageSize;
        _currentPage++;
      });
    } catch (error) {
      // Обработка ошибок
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreRecords() async {
    await _loadRecords();
  }

  Future<void> _refreshRecords() async {
    await _loadRecords(reset: true);
  }

  // Заглушка для загрузки записей по типу
  Future<List<dynamic>> _fetchRecordsForType(
    UniversalEntityType entityType,
    UniversalFilter filter,
    int page,
  ) async {
    // Имитация загрузки данных
    await Future.delayed(const Duration(milliseconds: 500));

    // Возвращаем тестовые данные
    return List.generate(
      page < 3 ? widget.pageSize : 5, // Меньше данных на последних страницах
      (index) => _createMockRecord(entityType, page * widget.pageSize + index),
    );
  }

  dynamic _createMockRecord(UniversalEntityType entityType, int index) {
    switch (entityType) {
      case UniversalEntityType.password:
        return {
          'id': 'password_$index',
          'name': 'Пароль $index',
          'username': 'user$index@example.com',
          'url': 'https://example$index.com',
          'isFavorite': index % 5 == 0,
          'createdAt': DateTime.now().subtract(Duration(days: index)),
        };
      case UniversalEntityType.note:
        return {
          'id': 'note_$index',
          'title': 'Заметка $index',
          'content': 'Содержимое заметки $index...',
          'isPinned': index % 7 == 0,
          'createdAt': DateTime.now().subtract(Duration(days: index)),
        };
      case UniversalEntityType.otp:
        return {
          'id': 'otp_$index',
          'issuer': 'Service $index',
          'accountName': 'account$index@service.com',
          'type': index % 2 == 0 ? 'TOTP' : 'HOTP',
          'createdAt': DateTime.now().subtract(Duration(days: index)),
        };
      case UniversalEntityType.attachment:
        return {
          'id': 'attachment_$index',
          'name': 'file_$index.pdf',
          'size': (index + 1) * 1024,
          'mimeType': 'application/pdf',
          'createdAt': DateTime.now().subtract(Duration(days: index)),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entityType = ref.watch(currentEntityTypeProvider);

    // Следим за изменениями фильтра и перезагружаем данные
    ref.listen(currentUniversalFilterProvider, (previous, next) {
      if (previous != next) {
        _loadRecords(reset: true);
      }
    });

    // Следим за изменениями типа сущности и перезагружаем данные
    ref.listen(currentEntityTypeProvider, (previous, next) {
      if (previous != next) {
        _loadRecords(reset: true);
      }
    });

    Widget content;

    if (_records.isEmpty && _isLoading) {
      // Начальная загрузка
      content = const Center(child: CircularProgressIndicator());
    } else if (_records.isEmpty) {
      // Нет данных
      content =
          widget.emptyWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getEmptyIcon(entityType),
                  size: 64,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.emptyMessage ?? _getEmptyMessage(entityType),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
    } else {
      // Список с данными
      content = ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _records.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _records.length) {
            // Индикатор загрузки в конце списка
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final record = _records[index];

          if (widget.itemBuilder != null) {
            return widget.itemBuilder!(context, record, index);
          }

          return _buildDefaultListItem(context, record, index);
        },
      );
    }

    if (widget.enableRefresh && widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh ?? _refreshRecords,
        child: content,
      );
    }

    return content;
  }

  Widget _buildDefaultListItem(
    BuildContext context,
    dynamic record,
    int index,
  ) {
    final theme = Theme.of(context);
    final entityType = ref.watch(currentEntityTypeProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            _getRecordIcon(entityType),
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(_getRecordTitle(record, entityType)),
        subtitle: Text(_getRecordSubtitle(record, entityType)),
        trailing: _buildRecordTrailing(record, entityType),
        onTap: widget.onRecordTap != null
            ? () => widget.onRecordTap!(record)
            : null,
        onLongPress: widget.onRecordLongPress != null
            ? () => widget.onRecordLongPress!(record)
            : null,
      ),
    );
  }

  Widget? _buildRecordTrailing(dynamic record, UniversalEntityType entityType) {
    final theme = Theme.of(context);

    switch (entityType) {
      case UniversalEntityType.password:
        if (record['isFavorite'] == true) {
          return Icon(Icons.star, color: theme.colorScheme.primary);
        }
        break;
      case UniversalEntityType.note:
        if (record['isPinned'] == true) {
          return Icon(Icons.push_pin, color: theme.colorScheme.primary);
        }
        break;
      default:
        break;
    }

    return const Icon(Icons.chevron_right);
  }

  IconData _getEmptyIcon(UniversalEntityType entityType) {
    switch (entityType) {
      case UniversalEntityType.password:
        return Icons.lock_outline;
      case UniversalEntityType.note:
        return Icons.note_outlined;
      case UniversalEntityType.otp:
        return Icons.security_outlined;
      case UniversalEntityType.attachment:
        return Icons.attachment_outlined;
    }
  }

  String _getEmptyMessage(UniversalEntityType entityType) {
    switch (entityType) {
      case UniversalEntityType.password:
        return 'Пароли не найдены';
      case UniversalEntityType.note:
        return 'Заметки не найдены';
      case UniversalEntityType.otp:
        return 'OTP коды не найдены';
      case UniversalEntityType.attachment:
        return 'Вложения не найдены';
    }
  }

  IconData _getRecordIcon(UniversalEntityType entityType) {
    switch (entityType) {
      case UniversalEntityType.password:
        return Icons.lock;
      case UniversalEntityType.note:
        return Icons.note;
      case UniversalEntityType.otp:
        return Icons.security;
      case UniversalEntityType.attachment:
        return Icons.attachment;
    }
  }

  String _getRecordTitle(dynamic record, UniversalEntityType entityType) {
    switch (entityType) {
      case UniversalEntityType.password:
        return record['name'] ?? 'Без названия';
      case UniversalEntityType.note:
        return record['title'] ?? 'Без заголовка';
      case UniversalEntityType.otp:
        return record['issuer'] ?? 'Неизвестный сервис';
      case UniversalEntityType.attachment:
        return record['name'] ?? 'Файл';
    }
  }

  String _getRecordSubtitle(dynamic record, UniversalEntityType entityType) {
    switch (entityType) {
      case UniversalEntityType.password:
        return record['username'] ?? record['url'] ?? '';
      case UniversalEntityType.note:
        final content = record['content'] ?? '';
        return content.length > 50 ? '${content.substring(0, 50)}...' : content;
      case UniversalEntityType.otp:
        return '${record['accountName']} (${record['type']})';
      case UniversalEntityType.attachment:
        final size = record['size'] as int? ?? 0;
        return '${_formatFileSize(size)} • ${record['mimeType'] ?? 'Unknown'}';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
