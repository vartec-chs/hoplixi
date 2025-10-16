import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/app/router/routes_path.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/providers/app_lifecycle_provider.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/models/database_entry.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';
import 'package:hoplixi/hoplixi_store/providers/providers.dart';
import 'package:hoplixi/shared/widgets/button.dart';
import 'package:hoplixi/shared/widgets/text_field.dart';

/// Экран разблокировки базы данных
class LockedDbScreen extends ConsumerStatefulWidget {
  const LockedDbScreen({super.key});

  @override
  ConsumerState<LockedDbScreen> createState() => _LockedDbScreenState();
}

class _LockedDbScreenState extends ConsumerState<LockedDbScreen> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  DatabaseEntry? _historyEntry;
  bool _hasSavedPassword = false;

  // Сохраняем путь и имя БД локально, чтобы не потерять при ошибке
  String? _dbPath;
  String? _dbName;

  @override
  void initState() {
    super.initState();
    _initializeDbInfo();
    _loadHistoryEntry();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  /// Инициализируем информацию о БД из состояния
  void _initializeDbInfo() {
    final dbState = ref.read(hoplixiStoreProvider).asData?.value;
    _dbPath = dbState?.path;
    _dbName = dbState?.name;

    logDebug(
      'Инициализация информации о БД',
      tag: 'LockedDbScreen',
      data: {'path': _dbPath, 'name': _dbName},
    );
  }

  /// Загружаем запись из истории, чтобы проверить наличие сохранённого пароля
  Future<void> _loadHistoryEntry() async {
    // Используем сохранённый путь или пытаемся получить из провайдера
    final path = _dbPath ?? ref.read(hoplixiStoreProvider).asData?.value.path;
    if (path == null) return;

    try {
      final manager = await ref.read(hoplixiStoreManagerProvider.future);
      final entry = await manager.getDatabaseHistoryEntry(path);

      if (mounted) {
        setState(() {
          _historyEntry = entry;
          _hasSavedPassword = entry?.masterPassword != null;
        });
      }

      logDebug(
        'История БД загружена',
        tag: 'LockedDbScreen',
        data: {'hasSavedPassword': _hasSavedPassword, 'path': path},
      );
    } catch (e) {
      logError('Ошибка загрузки истории БД', error: e, tag: 'LockedDbScreen');
    }
  }

  /// Разблокировка базы данных с введённым паролем
  Future<void> _unlockDatabase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Используем сохранённый путь (он не изменится даже если провайдер сбросится после ошибки)
    final path = _dbPath;
    if (path == null) {
      setState(() {
        _errorMessage = 'Путь к базе данных не найден';
        _isLoading = false;
      });
      return;
    }

    try {
      final dto = OpenDatabaseDto(
        path: path,
        masterPassword: _passwordController.text,
        saveMasterPassword: false,
      );

      await ref.read(hoplixiStoreProvider.notifier).openDatabase(dto);

      if (mounted) {
        // Сбрасываем флаг блокировки
        ref.read(appLifecycleProvider.notifier).resetDatabaseLockedFlag();

        logInfo('База данных разблокирована успешно', tag: 'LockedDbScreen');
        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      logError(
        'Ошибка разблокировки базы данных',
        error: e,
        tag: 'LockedDbScreen',
      );

      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  /// Автоматическое открытие с сохранённым паролем
  Future<void> _unlockWithSavedPassword() async {
    if (_historyEntry?.masterPassword == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Используем сохранённый путь
    final path = _dbPath;
    if (path == null) {
      setState(() {
        _errorMessage = 'Путь к базе данных не найден';
        _isLoading = false;
      });
      return;
    }

    try {
      final dto = OpenDatabaseDto(
        path: path,
        masterPassword: _historyEntry!.masterPassword!,
        saveMasterPassword: true,
      );

      await ref.read(hoplixiStoreProvider.notifier).openDatabase(dto);

      if (mounted) {
        // Сбрасываем флаг блокировки
        ref.read(appLifecycleProvider.notifier).resetDatabaseLockedFlag();

        logInfo(
          'База данных разблокирована с сохранённым паролем',
          tag: 'LockedDbScreen',
        );
        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      logError(
        'Ошибка разблокировки с сохранённым паролем',
        error: e,
        tag: 'LockedDbScreen',
      );

      if (mounted) {
        setState(() {
          _errorMessage =
              'Сохранённый пароль не подходит. Введите пароль вручную.';
          _isLoading = false;
        });
      }
    }
  }

  /// Закрыть базу данных и вернуться на главный экран
  Future<void> _closeAndGoHome() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Сначала сбрасываем флаг блокировки
      ref.read(appLifecycleProvider.notifier).resetDatabaseLockedFlag();

      // Затем закрываем БД
      await ref.read(hoplixiStoreProvider.notifier).closeDatabase();
      

      if (mounted) {
        logInfo(
          'База данных закрыта, переход на главный экран',
          tag: 'LockedDbScreen',
        );
        context.go(AppRoutes.home);
      }
    } catch (e) {
      logError(
        'Ошибка при закрытии базы данных',
        error: e,
        tag: 'LockedDbScreen',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(Object error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('password') || errorString.contains('пароль')) {
      return 'Неверный пароль';
    }

    if (errorString.contains('file') || errorString.contains('файл')) {
      return 'Файл базы данных недоступен';
    }

    return 'Ошибка разблокировки: ${error.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    // Используем сохранённое имя или пытаемся получить из провайдера
    final dbName =
        _dbName ??
        ref.watch(hoplixiStoreProvider).asData?.value.name ??
        'База данных';

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(12),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Иконка замка
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),

                // Заголовок
                Text(
                  'База данных заблокирована',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Введите мастер-пароль для разблокировки или воспользуйтесь сохранённым паролем',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Название базы данных
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 1),
                      borderRadius: BorderRadius.circular(16),
                    ),

                    child: Text(
                      dbName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Сообщение об ошибке
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.errorContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Поле ввода пароля
                PasswordField(
                  label: 'Мастер-пароль',
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите мастер-пароль';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Кнопка разблокировки
                SmoothButton(
                  label: 'Разблокировать',
                  onPressed: _isLoading ? null : _unlockDatabase,
                  loading: _isLoading,
                  type: SmoothButtonType.filled,
                ),
                const SizedBox(height: 12),

                // Кнопка автоматического открытия (если пароль сохранён)
                if (_hasSavedPassword) ...[
                  SmoothButton(
                    label: 'Открыть автоматически',
                    onPressed: _isLoading ? null : _unlockWithSavedPassword,
                    type: SmoothButtonType.outlined,
                    icon: const Icon(Icons.vpn_key, size: 20),
                  ),
                  const SizedBox(height: 12),
                ],

                // Кнопка "Домой"
                SmoothButton(
                  label: 'Закрыть и вернуться на главный экран',
                  onPressed: _isLoading ? null : _closeAndGoHome,
                  type: SmoothButtonType.text,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
