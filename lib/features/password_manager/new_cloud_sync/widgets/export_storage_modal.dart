import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/auth/widgets/auth_modal.dart';
import 'package:hoplixi/features/password_manager/new_cloud_sync/providers/export_controller_provider.dart';

/// Модальное окно для экспорта хранилища в облако
class ExportStorageModal extends ConsumerStatefulWidget {
  const ExportStorageModal({super.key});

  @override
  ConsumerState<ExportStorageModal> createState() => _ExportStorageModalState();
}

class _ExportStorageModalState extends ConsumerState<ExportStorageModal> {
  String? _clientKey;
  bool _isExporting = false;
  double _progress = 0.0;
  String _statusMessage = 'Подготовка к экспорту...';
  String? _errorMessage;
  String? _uploadInfo; // Дополнительная информация о загрузке (МБ/МБ, скорость)

  DateTime? _uploadStartTime;
  double? _lastUploadProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Заголовок
              Row(
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Экспорт хранилища',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!_isExporting)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Контент
              Expanded(
                child: _isExporting
                    ? _buildExportingState(theme)
                    : _buildInitialState(theme),
              ),

              // Действия
              if (!_isExporting) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _clientKey == null ? null : _startExport,
                      icon: const Icon(Icons.upload),
                      label: const Text('Экспортировать'),
                    ),
                  ],
                ),
              ] else if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Закрыть'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Иконка состояния
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _clientKey == null ? Icons.cloud_off : Icons.cloud_done,
            size: 64,
            color: _clientKey == null
                ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),

        // Текст статуса
        Text(
          _clientKey == null ? 'Авторизация в облаке' : 'Готово к экспорту',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _clientKey == null
              ? 'Для экспорта хранилища необходимо авторизоваться в облачном сервисе'
              : 'Ваше хранилище будет экспортировано в защищённый архив и загружено в облако',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Кнопка авторизации
        if (_clientKey == null)
          FilledButton.icon(
            onPressed: _handleAuthorization,
            icon: const Icon(Icons.login),
            label: const Text('Авторизоваться'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Авторизация успешна',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ключ: ${_maskKey(_clientKey!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Переавторизоваться',
                  onPressed: () {
                    setState(() {
                      _clientKey = null;
                    });
                    _handleAuthorization();
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildExportingState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Анимированная иконка
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 2),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (value * 0.2),
              child: Opacity(
                opacity: 0.5 + (value * 0.5),
                child: Icon(
                  _errorMessage != null
                      ? Icons.error_outline
                      : Icons.cloud_upload,
                  size: 80,
                  color: _errorMessage != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
            );
          },
          onEnd: () {
            if (mounted && _isExporting) {
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 32),

        // Прогресс
        if (_errorMessage == null)
          SizedBox(
            width: double.infinity,
            child: LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              backgroundColor: theme.colorScheme.primaryContainer.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(8),
              minHeight: 8,
            ),
          )
        else
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _progress,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),

        // Статус
        Text(
          _errorMessage ?? _statusMessage,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: _errorMessage != null ? theme.colorScheme.error : null,
          ),
          textAlign: TextAlign.center,
        ),
        if (_progress > 0 && _errorMessage == null) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(_progress * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_uploadInfo != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _uploadInfo!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
        const SizedBox(height: 32),

        // Подсказка или кнопка при ошибке
        if (_errorMessage != null)
          FilledButton.icon(
            onPressed: () {
              setState(() {
                _isExporting = false;
                _errorMessage = null;
                _progress = 0.0;
                _statusMessage = 'Подготовка к экспорту...';
                _uploadInfo = null;
                _uploadStartTime = null;
                _lastUploadProgress = null;
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Попробовать снова'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Не закрывайте это окно до завершения экспорта',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Обработчик авторизации
  Future<void> _handleAuthorization() async {
    try {
      final clientKey = await showAuthModal(context);

      if (clientKey != null && mounted) {
        setState(() {
          _clientKey = clientKey;
        });

        logInfo(
          'Авторизация успешна для экспорта',
          tag: 'ExportStorageModal',
          data: {'clientKey': _maskKey(clientKey)},
        );
      }
    } catch (e) {
      logError(
        'Ошибка авторизации для экспорта',
        error: e,
        tag: 'ExportStorageModal',
      );

      if (mounted) {
        ToastHelper.error(
          title: 'Ошибка авторизации',
          description: e.toString(),
        );
      }
    }
  }

  /// Запуск процесса экспорта
  Future<void> _startExport() async {
    if (_clientKey == null) return;

    setState(() {
      _isExporting = true;
      _progress = 0.0;
      _statusMessage = 'Подготовка к экспорту...';
      _errorMessage = null;
      _uploadInfo = null;
      _uploadStartTime = null;
      _lastUploadProgress = null;
    });

    try {
      final controller = ref.read(exportControllerProvider.notifier);

      // Запускаем экспорт
      await controller.exportToDropbox(
        clientKey: _clientKey!,
        onProgress: (progress, message) {
          if (mounted) {
            setState(() {
              _progress = progress;

              // Отслеживаем начало загрузки
              if (message.contains('Загрузка:') && _uploadStartTime == null) {
                _uploadStartTime = DateTime.now();
                _lastUploadProgress = progress;
              }

              // Парсим сообщение для извлечения информации о загрузке
              if (message.contains('Загрузка:') && message.contains('МБ')) {
                // Формат: "Загрузка: X.XX МБ / Y.YY МБ (ZZ.Z%)"
                final parts = message.split('Загрузка:');
                if (parts.length > 1) {
                  _statusMessage = 'Загрузка архива в Dropbox';

                  String uploadInfoText = parts[1].trim();

                  // Добавляем скорость загрузки
                  if (_uploadStartTime != null && _lastUploadProgress != null) {
                    final elapsed = DateTime.now().difference(
                      _uploadStartTime!,
                    );
                    if (elapsed.inSeconds > 0) {
                      final progressDiff = progress - _lastUploadProgress!;

                      // Извлекаем общий размер из сообщения
                      final totalMatch = RegExp(
                        r'/ ([\d.]+) МБ',
                      ).firstMatch(uploadInfoText);
                      if (totalMatch != null) {
                        final totalMB =
                            double.tryParse(totalMatch.group(1) ?? '0') ?? 0;
                        if (totalMB > 0) {
                          final uploadedMB =
                              progressDiff *
                              totalMB /
                              0.3; // 0.3 = диапазон прогресса загрузки
                          final speedMBps = uploadedMB / elapsed.inSeconds;

                          if (speedMBps > 0 && speedMBps < 1000) {
                            uploadInfoText +=
                                ' • ${speedMBps.toStringAsFixed(2)} МБ/с';
                          }
                        }
                      }
                    }
                  }

                  _uploadInfo = uploadInfoText;
                  _lastUploadProgress = progress;
                } else {
                  _statusMessage = message;
                  _uploadInfo = null;
                }
              } else {
                _statusMessage = message;
                if (!message.contains('Загрузка')) {
                  _uploadInfo = null;
                  _uploadStartTime = null;
                  _lastUploadProgress = null;
                }
              }

              _errorMessage = null;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = error;
              _isExporting =
                  true; // Оставляем в режиме экспорта для отображения ошибки
            });

            logError(
              'Ошибка при экспорте (из callback)',
              tag: 'ExportStorageModal',
              data: {'error': error},
            );
          }
        },
      );

      if (mounted && _errorMessage == null) {
        ToastHelper.success(
          title: 'Экспорт завершён',
          description: 'Хранилище успешно экспортировано в облако',
        );

        Navigator.of(context).pop(true);
      }
    } catch (e, st) {
      logError(
        'Ошибка экспорта хранилища',
        error: e,
        stackTrace: st,
        tag: 'ExportStorageModal',
      );

      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка: ${e.toString()}';
        });

        ToastHelper.error(title: 'Ошибка экспорта', description: e.toString());
      }
    }
  }

  /// Маскирует ключ для отображения
  String _maskKey(String key) {
    if (key.length <= 8) {
      return '${key.substring(0, 2)}***';
    }
    return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
  }
}

/// Вспомогательная функция для показа модального окна экспорта
Future<bool?> showExportStorageModal(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const ExportStorageModal(),
  );
}
