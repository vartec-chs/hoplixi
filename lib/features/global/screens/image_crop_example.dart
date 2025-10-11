/// Пример использования экрана обрезки изображений (ImageCropScreen)
///
/// Этот файл демонстрирует различные сценарии использования экрана обрезки.
/// Для интеграции в реальный код скопируйте нужный метод в свой экран.

library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/global/screens/image_crop_screen.dart';
import 'package:hoplixi/router/routes_path.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

/// ПРИМЕР 1: Простая обрезка изображения из галереи
class SimpleCropExample extends ConsumerWidget {
  const SimpleCropExample({super.key});

  Future<void> _pickAndCropImage(BuildContext context) async {
    // Шаг 1: Выбираем изображение
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null && context.mounted) {
      // Шаг 2: Читаем байты
      final bytes = await pickedFile.readAsBytes();

      // Шаг 3: Создаём данные для экрана обрезки
      final imageData = ImageCropData(
        imageBytes: bytes,
        sourceName: 'Фото из галереи',
      );

      // Шаг 4: Переходим на экран обрезки
      final result = await context.push(AppRoutes.imageCrop, extra: imageData);

      // Шаг 5: Обрабатываем результат
      if (result != null && result is CroppedImageResult && context.mounted) {
        ToastHelper.success(
          title: 'Изображение обрезано',
          description:
              'Размер: ${result.imageSize.width.toInt()}x${result.imageSize.height.toInt()}',
        );

        // Используем обрезанное изображение
        // result.croppedImageBytes - байты изображения
        // result.croppedImageWidget - виджет для отображения
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => _pickAndCropImage(context),
      child: const Text('Обрезать изображение'),
    );
  }
}

/// ПРИМЕР 2: Обрезка изображения с QR-кодом
class QRCodeCropExample extends ConsumerStatefulWidget {
  const QRCodeCropExample({super.key});

  @override
  ConsumerState<QRCodeCropExample> createState() => _QRCodeCropExampleState();
}

class _QRCodeCropExampleState extends ConsumerState<QRCodeCropExample> {
  String? _qrCodeData;

  Future<void> _pickImageAndDecodeQR() async {
    // Шаг 1: Выбираем изображение
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null && mounted) {
      final bytes = await pickedFile.readAsBytes();

      // Шаг 2: Даём пользователю обрезать изображение
      final cropResult = await context.push(
        AppRoutes.imageCrop,
        extra: ImageCropData(imageBytes: bytes, sourceName: 'QR-код'),
      );

      if (cropResult != null && cropResult is CroppedImageResult && mounted) {
        // Шаг 3: Декодируем QR из обрезанного изображения
        final image = img.decodeImage(cropResult.croppedImageBytes);

        if (image != null) {
          final source = RGBLuminanceSource(
            image.width,
            image.height,
            image
                .convert(numChannels: 4)
                .getBytes(order: img.ChannelOrder.abgr)
                .buffer
                .asInt32List(),
          );
          final bitmap = BinaryBitmap(GlobalHistogramBinarizer(source));
          final reader = QRCodeReader();

          try {
            final result = reader.decode(bitmap);
            setState(() {
              _qrCodeData = result.text;
            });
            ToastHelper.success(title: 'QR-код успешно декодирован');
          } catch (e) {
            ToastHelper.error(
              title: 'Не удалось декодировать QR-код',
              description: 'Попробуйте обрезать изображение точнее',
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _pickImageAndDecodeQR,
          child: const Text('Загрузить QR-код'),
        ),
        if (_qrCodeData != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Данные QR: $_qrCodeData'),
          ),
      ],
    );
  }
}

/// ПРИМЕР 3: Обрезка для аватара/иконки
class AvatarCropExample extends ConsumerStatefulWidget {
  const AvatarCropExample({super.key});

  @override
  ConsumerState<AvatarCropExample> createState() => _AvatarCropExampleState();
}

class _AvatarCropExampleState extends ConsumerState<AvatarCropExample> {
  Uint8List? _avatarBytes;

  Future<void> _selectAndCropAvatar() async {
    // Выбираем изображение с ограничением размера
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (pickedFile != null && mounted) {
      final bytes = await pickedFile.readAsBytes();

      final cropResult = await context.push(
        AppRoutes.imageCrop,
        extra: ImageCropData(imageBytes: bytes, sourceName: 'Аватар'),
      );

      if (cropResult != null && cropResult is CroppedImageResult) {
        setState(() {
          _avatarBytes = cropResult.croppedImageBytes;
        });

        ToastHelper.success(title: 'Аватар загружен');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_avatarBytes != null)
          CircleAvatar(radius: 50, backgroundImage: MemoryImage(_avatarBytes!))
        else
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _selectAndCropAvatar,
          child: const Text('Выбрать аватар'),
        ),
      ],
    );
  }
}

/// ПРИМЕР 4: Обрезка с сохранением в файл
class SaveCroppedImageExample extends ConsumerWidget {
  const SaveCroppedImageExample({super.key});

  Future<void> _cropAndSaveImage(BuildContext context) async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null && context.mounted) {
      final bytes = await pickedFile.readAsBytes();

      final cropResult = await context.push(
        AppRoutes.imageCrop,
        extra: ImageCropData(
          imageBytes: bytes,
          sourceName: 'Изображение для сохранения',
        ),
      );

      if (cropResult != null && cropResult is CroppedImageResult) {
        // Здесь можно сохранить в файл, базу данных, или отправить на сервер
        final croppedBytes = cropResult.croppedImageBytes;

        // Пример: сохранение в файл (требует path_provider)
        // final directory = await getApplicationDocumentsDirectory();
        // final file = File('${directory.path}/cropped_image_${DateTime.now().millisecondsSinceEpoch}.png');
        // await file.writeAsBytes(croppedBytes);

        ToastHelper.success(
          title: 'Изображение обрезано',
          description: 'Размер: ${croppedBytes.length ~/ 1024} KB',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => _cropAndSaveImage(context),
      child: const Text('Обрезать и сохранить'),
    );
  }
}
