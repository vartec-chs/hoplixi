# OTP Edit Modal

## Описание
Модальное окно для редактирования базовых полей OTP (TOTP/HOTP) кодов.

## Возможности
Позволяет редактировать следующие поля OTP кода:
- **issuer** - Издатель (обязательное поле)
- **accountName** - Имя аккаунта
- **categoryId** - Категория
- **tagIds** - Теги (множественный выбор, до 5 тегов)
- **isFavorite** - Флаг избранного

## Использование

### Открытие модального окна

```dart
import 'package:hoplixi/features/password_manager/dashboard/futures/otp_edit_modal.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';

// Используя хелпер
final result = await OtpEditModalHelper.show(context, otpDto);
if (result == true) {
  // Изменения были сохранены
  // Обновите список OTP
}

// Или напрямую
final result = await showDialog<bool>(
  context: context,
  builder: (context) => OtpEditModal(otp: otpDto),
);
```

### Параметры

- `otp` (CardOtpDto) - DTO с данными OTP для редактирования

### Возвращаемое значение

- `true` - изменения были сохранены
- `false` или `null` - изменения отменены

## Архитектура

### Сервисный слой

Модальное окно использует новый метод `TOTPService.updateTotpBasic()`:

```dart
final result = await otpService.updateTotpBasic(
  id: otpId,
  issuer: 'Google',
  accountName: 'user@example.com',
  categoryId: categoryId,
  tagIds: ['tag1', 'tag2'],
  isFavorite: true,
);
```

### DAO слой

Добавлены методы для работы с тегами OTP в `OtpsDao`:

- `getOtpTagIds(String otpId)` - получение ID тегов
- `addTagToOtp(String otpId, String tagId)` - добавление тега
- `removeTagFromOtp(String otpId, String tagId)` - удаление тега
- `setOtpTags(String otpId, List<String> tagIds)` - установка всех тегов
- `clearOtpTags(String otpId)` - очистка всех тегов

## Безопасность

- Секретный ключ OTP **НЕ** редактируется через это модальное окно
- Изменение секрета считается небезопасной операцией
- Для изменения секрета нужно создать новый OTP код

## Валидация

- **issuer** - обязательное поле, не может быть пустым
- **accountName** - опциональное поле
- **categoryId** - проверяется существование категории в БД
- **tagIds** - максимум 5 тегов

## Интеграция

Модальное окно интегрировано в:
- `EntityListView` - вызов при клике на кнопку "Редактировать"
- `EntityActionModal` - контекстное меню OTP карточки
- `OtpCard` - обработчик `onEdit`

## Зависимости

- `CategoriesPicker` - выбор категории
- `TagsPicker` - выбор тегов
- `TOTPService` - сервис для работы с OTP
- `PrimaryTextField` - кастомные текстовые поля
- `SmoothButton` - кастомные кнопки

## Рекомендации

1. **Не генерировать код вручную** - используйте `build_runner` после изменения DTO
2. **Следуйте ServiceResult паттерну** - все ошибки через `ServiceResult<T>`
3. **Логируйте операции** - используйте `logInfo/logError` из `app_logger.dart`
4. **Не логируйте секреты** - никогда не выводите в лог расшифрованные секреты
