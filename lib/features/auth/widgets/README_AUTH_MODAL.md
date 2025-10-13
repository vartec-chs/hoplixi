# AuthModal

Модальное окно для выбора OAuth провайдера и выполнения авторизации.

## Описание

`AuthModal` — это интерактивное модальное окно, которое отображает доступные OAuth провайдеры (Google, OneDrive, Dropbox, Yandex, iCloud) с анимированной загрузкой кнопок. Показываются только те провайдеры, для которых существуют сохранённые credentials.

## Основные возможности

1. **Постепенная загрузка кнопок** — кнопки провайдеров появляются по одной с плавной анимацией (fade-in + slide)
2. **Фильтрация по credentials** — отображаются только провайдеры, для которых есть хотя бы один credential
3. **Выбор credential** — если для провайдера несколько credentials, показывается диалог выбора
4. **Авторизация OAuth** — выполняет полный flow авторизации с визуальной обратной связью
5. **Адаптивный UI** — показывает состояния загрузки, ошибок и пустого списка

## Использование

### Базовое использование

```dart
import 'package:hoplixi/features/cloud_sync/widgets/auth_modal.dart';

// Вариант 1: Через вспомогательную функцию
final authKey = await showAuthModal(context);
if (authKey != null) {
  print('Авторизация успешна: $authKey');
}

// Вариант 2: Напрямую через showDialog
final authKey = await showDialog<String>(
  context: context,
  builder: (context) => const AuthModal(),
);
```

### В кнопке

```dart
SmoothButton(
  label: 'Авторизоваться',
  onPressed: () async {
    final authKey = await showAuthModal(context);
    if (authKey != null) {
      ToastHelper.success(
        title: 'Авторизация успешна',
        description: 'Ключ: $authKey',
      );
    }
  },
  icon: const Icon(Icons.cloud),
)
```

### В меню настроек

```dart
ListTile(
  leading: const Icon(Icons.cloud_sync),
  title: const Text('Подключить облако'),
  subtitle: const Text('OAuth авторизация'),
  trailing: const Icon(Icons.arrow_forward_ios),
  onTap: () => showAuthModal(context),
)
```

## Анимация загрузки

Кнопки провайдеров загружаются последовательно с интервалом 150ms между каждой:

1. Модалка открывается
2. Через 100ms начинается загрузка первой кнопки
3. Каждая следующая кнопка появляется через 150ms
4. Анимация fade-in + slide вверх (300ms)

## Логика работы

```
1. Пользователь открывает модалку
   ↓
2. Загружаются все credentials
   ↓
3. Группируются по типам (CredentialOAuthType)
   ↓
4. Фильтруются типы с пустыми credentials
   ↓
5. Постепенно отображаются кнопки активных типов
   ↓
6. Пользователь выбирает провайдер
   ↓
7. Если несколько credentials для типа → диалог выбора
   ↓
8. Запуск OAuth авторизации
   ↓
9. Возврат ключа авторизации или null
```

## Возвращаемое значение

- `String?` — ключ авторизации при успехе
- `null` — если авторизация отменена или произошла ошибка

## Зависимости

### Провайдеры
- `credentialListProvider` — список всех credentials для фильтрации
- `oauth2AccountProvider` — сервис OAuth авторизации

### Сервисы
- `OAuth2AccountService` — выполнение OAuth flow (метод `authorizeWithDropbox`)

## Состояния UI

### Загрузка
Показывается `CircularProgressIndicator` при:
- Загрузке списка credentials
- Загрузке OAuth сервиса

### Пустой список
Отображается когда нет ни одного credential:
```
☁️ (иконка cloud_off)
Нет доступных провайдеров
Сначала добавьте учётные данные OAuth
```

### Ошибка
При ошибке загрузки:
```
⚠️ (иконка error_outline)
Ошибка загрузки
[текст ошибки]
```

### Авторизация в процессе
- Кнопка провайдера показывает `CircularProgressIndicator`
- Другие кнопки становятся неактивными
- Кнопка закрытия модалки отключается

## Карточка провайдера

Каждая карточка отображает:
- **Иконка** — цветная иконка провайдера
- **Название** — тип провайдера (Google, Dropbox и т.д.)
- **Счётчик** — количество доступных credentials
- **Индикатор** — стрелка или spinner при авторизации

## Выбор credential

Если для провайдера несколько credentials, показывается диалог:

```dart
AlertDialog(
  title: 'Выберите учётные данные',
  content: ListView [
    ListTile(
      title: credential.name,
      subtitle: 'ID: xxxx...xxxx',
    ),
    ...
  ],
)
```

## Поддерживаемые провайдеры

| Провайдер | Enum | Иконка | Цвет |
|-----------|------|--------|------|
| Google | `google` | cloud | blue |
| OneDrive | `onedrive` | cloud_circle | lightBlue |
| Dropbox | `dropbox` | cloud_queue | indigo |
| iCloud | `icloud` | cloud_done | cyan |
| Yandex | `yandex` | cloud_upload | red |
| Other | `other` | cloud_outlined | grey |

## Обработка ошибок

- Ошибки авторизации логируются через `logError`
- Пользователю показывается `ToastHelper.error`
- Модалка не закрывается при ошибке (можно повторить)

## Примеры интеграции

### Dashboard

```dart
Card(
  child: ListTile(
    leading: const Icon(Icons.cloud),
    title: const Text('Синхронизация'),
    subtitle: const Text('Подключить облачное хранилище'),
    trailing: ElevatedButton(
      onPressed: () => showAuthModal(context),
      child: const Text('Подключить'),
    ),
  ),
)
```

### Settings

```dart
ExpansionTile(
  title: const Text('Облачная синхронизация'),
  children: [
    ListTile(
      title: const Text('Добавить авторизацию'),
      leading: const Icon(Icons.add_circle_outline),
      onTap: () => showAuthModal(context),
    ),
  ],
)
```

### FAB

```dart
FloatingActionButton.extended(
  onPressed: () => showAuthModal(context),
  icon: const Icon(Icons.cloud_sync),
  label: const Text('Подключить облако'),
)
```

## Технические детали

### Анимация

```dart
AnimatedOpacity(
  opacity: isLoaded ? 1.0 : 0.0,
  duration: const Duration(milliseconds: 300),
  child: AnimatedSlide(
    offset: isLoaded ? Offset.zero : const Offset(0, 0.2),
    duration: const Duration(milliseconds: 300),
    child: ProviderCard(...),
  ),
)
```

### Задержки

- Начало загрузки: 100ms
- Между кнопками: 150ms
- Fade-in/Slide: 300ms

### Состояние

```dart
final Map<CredentialOAuthType, bool> _loadedButtons = {};
bool _isAuthorizing = false;
CredentialOAuthType? _authorizingType;
```

## Ограничения

- В данный момент поддерживается только Dropbox (`authorizeWithDropbox`)
- Для других провайдеров нужно расширить `OAuth2AccountService`
- Максимальная ширина модалки: 500px
- Максимальная высота: 600px

## TODO

- [ ] Добавить поддержку других провайдеров (Google, OneDrive и т.д.)
- [ ] Сохранение последнего выбранного credential
- [ ] Возможность быстрой повторной авторизации
- [ ] Индикатор уже авторизованных провайдеров
- [ ] Настройка скорости анимации

## Связанные файлы

- `credential_provider.dart` — провайдер списка credentials
- `oauth2_account_provider.dart` — провайдер OAuth сервиса
- `oauth2_account_service.dart` — сервис авторизации
- `credential_app.dart` — модель credential
