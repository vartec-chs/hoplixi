/// Экран обрезки изображения
///
/// Использует crop_image пакет для интерактивной обрезки изображений.
/// Поддерживает:
/// - Различные соотношения сторон (свободное, квадрат, 16:9, 4:3, и т.д.)
/// - Поворот изображения (влево/вправо)
/// - Сброс к исходному состоянию
/// - Возврат обрезанного изображения в виде Widget
///
/// Используется после выбора изображения из галереи для его обрезки перед сохранением.
library;

import 'dart:typed_data';
import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/global/widgets/button.dart';
import 'package:image/image.dart' as img;

/// Модель данных для передачи изображения в экран обрезки
class ImageCropData {
  final Uint8List imageBytes;
  final String? sourceName;

  const ImageCropData({required this.imageBytes, this.sourceName});
}

/// Модель результата обрезки
class CroppedImageResult {
  final Widget croppedImageWidget;
  final Uint8List croppedImageBytes;
  final Rect cropRect;
  final Size imageSize;

  const CroppedImageResult({
    required this.croppedImageWidget,
    required this.croppedImageBytes,
    required this.cropRect,
    required this.imageSize,
  });
}

class ImageCropScreen extends ConsumerStatefulWidget {
  final ImageCropData imageData;

  const ImageCropScreen({super.key, required this.imageData});

  @override
  ConsumerState<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends ConsumerState<ImageCropScreen> {
  static const String _logTag = 'ImageCropScreen';

  late final CropController _cropController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    // Инициализируем контроллер crop с дефолтными параметрами
    _cropController = CropController(
      aspectRatio: 1.0, // Квадрат по умолчанию
      defaultCrop: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
    );

    logInfo(
      'Инициализация экрана обрезки изображения${widget.imageData.sourceName != null ? " (${widget.imageData.sourceName})" : ""}',
      tag: _logTag,
    );
  }

  @override
  void dispose() {
    _cropController.dispose();
    super.dispose();
  }

  /// Показать диалог выбора соотношения сторон
  Future<void> _selectAspectRatio() async {
    final value = await showDialog<double>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return SimpleDialog(
          title: Text(
            'Выберите соотношение сторон',
            style: theme.textTheme.titleLarge,
          ),
          children: [
            _buildAspectRatioOption(
              context,
              'Свободное',
              -1.0,
              Icons.crop_free,
              colorScheme,
            ),
            _buildAspectRatioOption(
              context,
              'Квадрат (1:1)',
              1.0,
              Icons.crop_square,
              colorScheme,
            ),
            _buildAspectRatioOption(
              context,
              'Портрет (3:4)',
              3.0 / 4.0,
              Icons.crop_portrait,
              colorScheme,
            ),
            _buildAspectRatioOption(
              context,
              'Пейзаж (4:3)',
              4.0 / 3.0,
              Icons.crop_landscape,
              colorScheme,
            ),
            _buildAspectRatioOption(
              context,
              'Широкий (16:9)',
              16.0 / 9.0,
              Icons.panorama_wide_angle,
              colorScheme,
            ),
            _buildAspectRatioOption(
              context,
              'Вертикальный (9:16)',
              9.0 / 16.0,
              Icons.stay_current_portrait,
              colorScheme,
            ),
            _buildAspectRatioOption(
              context,
              'Кино (21:9)',
              21.0 / 9.0,
              Icons.crop_7_5,
              colorScheme,
            ),
            _buildAspectRatioOption(
              context,
              '2:1',
              2.0,
              Icons.crop_16_9,
              colorScheme,
            ),
          ],
        );
      },
    );

    if (value != null && mounted) {
      setState(() {
        _cropController.aspectRatio = value == -1.0 ? null : value;
        _cropController.crop = const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9);
      });

      logDebug(
        'Соотношение сторон изменено: ${value == -1.0 ? "свободное" : value}',
        tag: _logTag,
      );
    }
  }

  Widget _buildAspectRatioOption(
    BuildContext context,
    String label,
    double value,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 16),
            Text(label),
          ],
        ),
      ),
    );
  }

  /// Поворот изображения влево
  void _rotateLeft() {
    _cropController.rotateLeft();
    logDebug('Поворот изображения влево', tag: _logTag);
  }

  /// Поворот изображения вправо
  void _rotateRight() {
    _cropController.rotateRight();
    logDebug('Поворот изображения вправо', tag: _logTag);
  }

  /// Сброс к исходному состоянию
  void _reset() {
    setState(() {
      _cropController.rotation = CropRotation.up;
      _cropController.crop = const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9);
      _cropController.aspectRatio = 1.0;
    });

    ToastHelper.info(title: 'Сброшено к исходному состоянию');
    logDebug('Сброс обрезки к исходному состоянию', tag: _logTag);
  }

  /// Завершение обрезки и возврат результата
  Future<void> _finishCropping() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Получаем обрезанное изображение как Widget
      final croppedWidget = await _cropController.croppedImage();

      // Декодируем исходное изображение для получения байтов
      final decodedImage = img.decodeImage(widget.imageData.imageBytes);
      if (decodedImage == null) {
        throw Exception('Не удалось декодировать изображение');
      }

      // Получаем размеры обрезанной области
      final cropSize = _cropController.cropSize;
      final crop = _cropController.crop;

      logDebug(
        'Обрезка завершена: rect=$crop, size=$cropSize',
        tag: _logTag,
      );

      // Применяем поворот к изображению, если необходимо
      img.Image rotatedImage = decodedImage;
      switch (_cropController.rotation) {
        case CropRotation.right:
          rotatedImage = img.copyRotate(decodedImage, angle: 90);
          break;
        case CropRotation.left:
          rotatedImage = img.copyRotate(decodedImage, angle: -90);
          break;
        case CropRotation.down:
          rotatedImage = img.copyRotate(decodedImage, angle: 180);
          break;
        case CropRotation.up:
          // Не поворачиваем
          break;
      }

      // Вычисляем абсолютные координаты обрезки
      final cropX = (rotatedImage.width * crop.left).round();
      final cropY = (rotatedImage.height * crop.top).round();
      final cropWidth = (rotatedImage.width * crop.width).round();
      final cropHeight = (rotatedImage.height * crop.height).round();

      // Выполняем обрезку
      final croppedImage = img.copyCrop(
        rotatedImage,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      // Кодируем обрезанное изображение в PNG
      final croppedBytes = Uint8List.fromList(img.encodePng(croppedImage));

      // Создаём результат
      final result = CroppedImageResult(
        croppedImageWidget: croppedWidget,
        croppedImageBytes: croppedBytes,
        cropRect: crop,
        imageSize: Size(cropWidth.toDouble(), cropHeight.toDouble()),
      );

      if (mounted) {
        ToastHelper.success(title: 'Изображение обрезано');
        logInfo('Обрезка успешно завершена', tag: _logTag);
        context.pop(result);
      }
    } catch (e, stackTrace) {
      logError(
        'Ошибка при обрезке изображения: $e',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      ToastHelper.error(
        title: 'Ошибка обрезки',
        description: 'Не удалось обрезать изображение',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 450;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.imageData.sourceName ?? 'Обрезка изображения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
            tooltip: 'Сбросить',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Область обрезки изображения
            Expanded(
              child: Container(
                color: colorScheme.surfaceContainerHighest,
                child: Center(
                  child: CropImage(
                    controller: _cropController,
                    image: Image.memory(widget.imageData.imageBytes),
                    paddingSize: isMobile ? 16.0 : 25.0,
                    alwaysMove: true,
                    minimumImageSize: 100,
                    maximumImageSize: isMobile ? 400 : 800,
                    // Настройки визуального стиля
                    gridColor: colorScheme.primary.withOpacity(0.5),
                    gridCornerSize: 25,
                    gridThinWidth: 1,
                    gridThickWidth: 3,
                  ),
                ),
              ),
            ),

            // Панель инструментов
            Container(
              padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Кнопки управления
                  if (isMobile)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildToolButton(
                              context,
                              icon: Icons.aspect_ratio,
                              label: 'Пропорции',
                              onPressed: _selectAspectRatio,
                            ),
                            _buildToolButton(
                              context,
                              icon: Icons.rotate_left,
                              label: 'Влево',
                              onPressed: _rotateLeft,
                            ),
                            _buildToolButton(
                              context,
                              icon: Icons.rotate_right,
                              label: 'Вправо',
                              onPressed: _rotateRight,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SmoothButton(
                          isFullWidth: true,
                          label: 'Готово',
                          onPressed: _isProcessing ? null : _finishCropping,
                          type: SmoothButtonType.filled,
                          loading: _isProcessing,
                          icon: const Icon(Icons.check, size: 20),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildToolButton(
                          context,
                          icon: Icons.aspect_ratio,
                          label: 'Пропорции',
                          onPressed: _selectAspectRatio,
                        ),
                        const SizedBox(width: 12),
                        _buildToolButton(
                          context,
                          icon: Icons.rotate_left,
                          label: 'Влево',
                          onPressed: _rotateLeft,
                        ),
                        const SizedBox(width: 12),
                        _buildToolButton(
                          context,
                          icon: Icons.rotate_right,
                          label: 'Вправо',
                          onPressed: _rotateRight,
                        ),
                        const SizedBox(width: 24),
                        SmoothButton(
                          label: 'Готово',
                          onPressed: _isProcessing ? null : _finishCropping,
                          type: SmoothButtonType.filled,
                          loading: _isProcessing,
                          icon: const Icon(Icons.check, size: 20),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          iconSize: 28,
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
