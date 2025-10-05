# Обновление: Модальное окно редактирования OTP

## Что добавлено

### 1. Модальное окно редактирования OTP
**Файл:** `lib/features/password_manager/dashboard/futures/otp_edit_modal.dart`

Функционал:
- Редактирование issuer (издатель)
- Редактирование accountName (имя аккаунта)
- Выбор категории (CategoryPicker)
- Выбор тегов (TagsPicker, до 5 тегов)
- Переключение избранного (isFavorite)
- Валидация полей
- Асинхронная загрузка текущих данных
- Адаптивный дизайн (Dialog)

### 2. Расширен OtpsDao
**Файл:** `lib/hoplixi_store/dao/otps_dao.dart`

Новые методы для работы с тегами:
- `getOtpTagIds(String otpId)` - получение ID тегов OTP
- `addTagToOtp(String otpId, String tagId)` - добавление тега
- `removeTagFromOtp(String otpId, String tagId)` - удаление тега
- `setOtpTags(String otpId, List<String> tagIds)` - установка всех тегов
- `clearOtpTags(String otpId)` - очистка тегов

**Изменения:**
- Добавлена таблица `OtpTags` в `@DriftAccessor`
- Импортирован `../tables/otp_tags.dart`

### 3. Расширен TOTPService
**Файл:** `lib/hoplixi_store/services/totp_service.dart`

Новые методы:
- `updateTotpBasic()` - обновление базовых полей с поддержкой тегов
- `getOtpTagIds()` - получение ID тегов для OTP

Метод `updateTotpBasic` принимает:
```dart
Future<ServiceResult<bool>> updateTotpBasic({
  required String id,
  String? issuer,
  String? accountName,
  String? categoryId,
  List<String>? tagIds,
  bool? isFavorite,
})
```

### 4. Интеграция в UI
**Файл:** `lib/features/password_manager/dashboard/widgets/entity_list_view.dart`

Обновлен метод `_onOtpEdit()`:
```dart
void _onOtpEdit(CardOtpDto otp) async {
  final result = await OtpEditModalHelper.show(context, otp);
  if (result == true && mounted) {
    ref.read(paginatedOtpsProvider.notifier).refresh();
  }
}
```

## Как использовать

1. **В карточке OTP** - нажать кнопку "Редактировать"
2. **В контекстном меню** - выбрать "Редактировать" при долгом нажатии
3. **Программно:**
   ```dart
   final result = await OtpEditModalHelper.show(context, otpDto);
   if (result == true) {
     // Обновить список
   }
   ```

## Безопасность

✅ Секретный ключ OTP **НЕ РЕДАКТИРУЕТСЯ**  
✅ Все изменения через `ServiceResult<T>`  
✅ Валидация перед сохранением  
✅ Проверка существования категории  
✅ Транзакции при обновлении тегов  
✅ Логирование без чувствительных данных

## Что НЕ делать

❌ НЕ редактировать секрет OTP (небезопасно)  
❌ НЕ изменять алгоритм, период, количество цифр  
❌ НЕ логировать расшифрованные секреты  
❌ НЕ обходить валидацию

## Следующие шаги

Для применения изменений необходимо:

1. **Запустить build_runner** (обязательно):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
   
2. **Проверить отсутствие ошибок**:
   ```bash
   flutter analyze
   ```

3. **Протестировать:**
   - Открытие модального окна
   - Редактирование полей
   - Выбор категории
   - Выбор тегов
   - Сохранение изменений
   - Отмена изменений

## Архитектурные решения

1. **Не создавали новый DTO** - используем существующий `UpdateTotpDto` через метод сервиса
2. **Разделение ответственности** - DAO работает с БД, Service с бизнес-логикой
3. **ServiceResult паттерн** - единообразная обработка ошибок
4. **Использование существующих компонентов** - CategoriesPicker, TagsPicker
5. **Адаптивность** - Dialog для desktop (можно расширить для mobile)

## Технический долг

- [ ] Добавить поддержку BottomSheet для мобильных устройств
- [ ] Добавить анимации открытия/закрытия
- [ ] Добавить автосохранение в draft
- [ ] Добавитьundo/redo функционал
