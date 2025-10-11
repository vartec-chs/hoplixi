# Global Screens

Общие экраны приложения, используемые в различных модулях.

## ImageCropScreen

Экран для интерактивной обрезки изображений с использованием пакета `crop_image`.

### Возможности

- ✂️ Интерактивная обрезка изображений
- 📐 Различные соотношения сторон (свободное, 1:1, 4:3, 16:9, и др.)
- 🔄 Поворот изображения (влево/вправо)
- ↩️ Сброс к исходному состоянию
- 📱 Адаптивный дизайн (mobile/desktop)
- 🎨 Соответствует дизайн-системе проекта

### Использование

#### 1. Импорт необходимых компонентов

```dart
import 'package:hoplixi/features/global/screens/image_crop_screen.dart';
import 'package:hoplixi/router/routes_path.dart';
import 'package:image_picker/image_picker.dart';
```

#### 2. Выбор изображения из галереи

```dart
Future<void> _pickAndCropImage() async {
  // Выбираем изображение
  final pickedFile = await ImagePicker().pickImage(
    source: ImageSource.gallery,
  );
  
  if (pickedFile != null) {
    final bytes = await pickedFile.readAsBytes();
    
    // Создаём данные для передачи в экран обрезки
    final imageData = ImageCropData(
      imageBytes: bytes,
      sourceName: 'Импорт QR-кода', // Опционально
    );
    
    // Переходим на экран обрезки и ожидаем результат
    final result = await context.push(
      AppRoutes.imageCrop,
      extra: imageData,
    );
    
    // Обрабатываем результат
    if (result != null && result is CroppedImageResult) {
      // result.croppedImageWidget - Widget с обрезанным изображением
      // result.croppedImageBytes - байты обрезанного изображения (PNG)
      // result.cropRect - область обрезки (Rect)
      // result.imageSize - размер обрезанного изображения
      
      // Используем обрезанное изображение
      _processImage(result.croppedImageBytes);
    }
  }
}
```

#### 3. Пример интеграции с QR-кодом (как в ImportOtpScreen)

```dart
Future<void> _pickImageAndDecodeQR() async {
  final pickedFile = await ImagePicker().pickImage(
    source: ImageSource.gallery,
  );
  
  if (pickedFile != null) {
    final bytes = await pickedFile.readAsBytes();
    
    // Показываем экран обрезки
    final cropResult = await context.push(
      AppRoutes.imageCrop,
      extra: ImageCropData(
        imageBytes: bytes,
        sourceName: 'QR-код для импорта',
      ),
    );
    
    if (cropResult != null && cropResult is CroppedImageResult && mounted) {
      // Используем обрезанное изображение для декодирования QR
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
          // Обрабатываем QR-код
          _processQRCode(result.text);
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
```

#### 4. Пример для загрузки аватара/иконки

```dart
Future<void> _selectAndCropAvatar() async {
  final pickedFile = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1024,
    maxHeight: 1024,
  );
  
  if (pickedFile != null) {
    final bytes = await pickedFile.readAsBytes();
    
    final cropResult = await context.push(
      AppRoutes.imageCrop,
      extra: ImageCropData(
        imageBytes: bytes,
        sourceName: 'Аватар пользователя',
      ),
    );
    
    if (cropResult != null && cropResult is CroppedImageResult) {
      // Сохраняем обрезанное изображение
      setState(() {
        _avatarBytes = cropResult.croppedImageBytes;
      });
      
      // Или отображаем сразу
      Image.memory(cropResult.croppedImageBytes);
    }
  }
}
```

### Архитектурные принципы

✅ **Следует архитектуре Hoplixi:**
- Использует `ToastHelper` для уведомлений
- Логирование через `app_logger.dart`
- Кастомные UI-компоненты (`SmoothButton`)
- Адаптивный дизайн (mobile/tablet/desktop)
- Корректная обработка ошибок через try-catch
- ServiceResult паттерн не требуется (UI-only компонент)

✅ **Безопасность:**
- Не логирует содержимое изображений
- Корректная обработка ошибок декодирования
- Валидация входных данных

✅ **UX:**
- Индикатор загрузки при обработке
- Понятные подсказки (tooltips)
- Возможность сброса к исходному состоянию
- Отмена через системную кнопку "Назад"

### Модель данных

#### ImageCropData
Входные данные для экрана обрезки.

```dart
class ImageCropData {
  final Uint8List imageBytes;  // Байты изображения (обязательно)
  final String? sourceName;     // Имя источника (опционально, для отображения)
}
```

#### CroppedImageResult
Результат обрезки изображения.

```dart
class CroppedImageResult {
  final Widget croppedImageWidget;    // Widget для отображения
  final Uint8List croppedImageBytes;  // Байты обрезанного изображения (PNG)
  final Rect cropRect;                // Область обрезки (0.0-1.0)
  final Size imageSize;               // Размер обрезанного изображения
}
```

### Доступные соотношения сторон

- 🆓 **Свободное** - без ограничений
- ⬜ **Квадрат (1:1)** - для аватаров, иконок
- 📱 **Портрет (3:4)** - вертикальные фото
- 🖼️ **Пейзаж (4:3)** - горизонтальные фото
- 📺 **Широкий (16:9)** - стандартное видео
- 📲 **Вертикальный (9:16)** - мобильное видео
- 🎬 **Кино (21:9)** - кинематографический формат
- 📏 **2:1** - панорама

### Управление

| Действие | Кнопка | Описание |
|----------|--------|----------|
| Пропорции | 📐 | Выбор соотношения сторон |
| Поворот влево | ↺ | Поворот на 90° против часовой |
| Поворот вправо | ↻ | Поворот на 90° по часовой |
| Сброс | ↩️ | Возврат к исходному состоянию |
| Готово | ✓ | Завершение обрезки |

### Технические детали

- **Библиотека:** `crop_image: ^1.0.16`
- **Обработка изображений:** `image` package
- **Формат вывода:** PNG (Uint8List)
- **Минимальный размер:** 100px
- **Максимальный размер:** 400px (mobile), 800px (desktop)
- **Логирование:** `ImageCropScreen` tag

### Пример в проекте

См. потенциальную интеграцию в:
- `lib/features/password_manager/dashboard/screens/import_otp_screen.dart` - для обрезки QR-кодов перед сканированием
- `lib/features/password_manager/icons_manager/` - для загрузки кастомных иконок
- Любые сценарии, где требуется обрезка изображений

### Навигация

Маршрут зарегистрирован в `lib/router/routes_path.dart` как `AppRoutes.imageCrop`.

**⚠️ Важно:** Обязательно передавайте `ImageCropData` через параметр `extra` при навигации!

```dart
context.push(AppRoutes.imageCrop, extra: imageData);
```

Без `extra` будет показан экран ошибки.
