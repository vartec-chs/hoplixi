# Модуль Cloud Sync - Управление Credential

## Описание

Модуль для управления учётными данными OAuth-приложений для будущей облачной синхронизации. Данные хранятся в зашифрованной BoxDB.

## Структура

```
lib/features/cloud_sync/
├── models/
│   ├── credential_app.dart          # Freezed модель credential
│   ├── credential_app.freezed.dart
│   └── credential_app.g.dart
├── services/
│   └── credential_service.dart      # Сервис для работы с credentials
├── providers/
│   └── credential_provider.dart     # Riverpod провайдеры
├── screens/
│   └── manage_credential_screen.dart # Экран управления
└── widgets/
    ├── credential_card.dart         # Карточка credential
    └── credential_form_dialog.dart  # Форма добавления/редактирования
```

## Компоненты

### 1. CredentialService

Сервис для работы с учётными данными через BoxDB.

**Основные методы:**
- `createCredential()` - создать новый credential
- `getCredential(id)` - получить по ID
- `getAllCredentials()` - получить все
- `getCredentialsByType(type)` - фильтр по типу
- `updateCredential(credential)` - обновить
- `deleteCredential(id)` - удалить
- `getExpiredCredentials()` - получить истёкшие
- `clearAll()` - очистить всё
- `getCount()` - количество

**Все методы возвращают `ServiceResult<T>`** с полями:
- `success` - успех операции
- `message` - сообщение пользователю
- `data` - результат (если success=true)

### 2. Провайдеры

**credentialServiceProvider** - провайдер сервиса
```dart
final service = ref.read(credentialServiceProvider);
```

**credentialListProvider** - состояние списка credentials
```dart
final state = ref.watch(credentialListProvider);
// state.credentials - список
// state.isLoading - загрузка
// state.error - ошибка
```

**CredentialListNotifier** - управление списком:
- `refresh()` - обновить
- `createCredential()` - создать
- `updateCredential()` - обновить
- `deleteCredential()` - удалить
- `getExpiredCredentials()` - истёкшие
- `clearAll()` - очистить

**Дополнительные провайдеры:**
- `activeCredentialsProvider` - только активные типы
- `credentialsByTypeProvider` - группировка по типам

### 3. ManageCredentialScreen

Экран управления учётными данными.

**Функциональность:**
- Список всех credentials
- Добавление нового
- Редактирование существующего
- Удаление с подтверждением
- Pull-to-refresh
- Индикаторы истёкших credentials
- Пустое состояние
- Обработка ошибок

### 4. Виджеты

**CredentialCard** - карточка credential:
- Иконка по типу
- Название типа
- Маскированный Client ID
- Redirect URI
- Дата истечения с предупреждением
- Кнопки редактирования и удаления
- Индикатор неактивного типа

**CredentialFormDialog** - диалог формы:
- Выбор типа (dropdown)
- Поля: Client ID, Client Secret, Redirect URI
- Выбор даты истечения
- Валидация полей
- Режимы создания/редактирования
- Индикатор загрузки

## Использование

### Навигация к экрану

```dart
// Добавить в router
GoRoute(
  path: '/credentials',
  builder: (context, state) => const ManageCredentialScreen(),
),
```

### Работа с сервисом напрямую

```dart
final service = ref.read(credentialServiceProvider);

// Создать
final result = await service.createCredential(
  type: CredentialOAuthType.dropbox,
  clientId: 'your_client_id',
  clientSecret: 'your_client_secret',
  redirectUri: 'https://yourapp.com/callback',
  expiresAt: DateTime.now().add(Duration(days: 365)),
);

if (!result.success) {
  ToastHelper.error(title: result.message!);
} else {
  final credential = result.data!;
  // использовать credential
}

// Получить все
final allResult = await service.getAllCredentials();
if (allResult.success) {
  final credentials = allResult.data!;
  // использовать список
}
```

### Использование провайдера

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(credentialListProvider);
    
    if (state.isLoading) {
      return CircularProgressIndicator();
    }
    
    if (state.error != null) {
      return Text('Ошибка: ${state.error}');
    }
    
    return ListView.builder(
      itemCount: state.credentials.length,
      itemBuilder: (context, index) {
        final credential = state.credentials[index];
        return ListTile(
          title: Text(credential.type.name),
          subtitle: Text(credential.clientId),
        );
      },
    );
  }
}

// Создание
await ref.read(credentialListProvider.notifier).createCredential(
  type: CredentialOAuthType.dropbox,
  clientId: 'id',
  clientSecret: 'secret',
  redirectUri: 'uri',
  expiresAt: DateTime.now().add(Duration(days: 365)),
);

// Удаление
await ref.read(credentialListProvider.notifier).deleteCredential(id);
```

## Модель данных

```dart
@freezed
class CredentialApp with _$CredentialApp {
  const factory CredentialApp({
    required String id,
    required CredentialOAuthType type,
    required String clientId,
    required String clientSecret,
    required String redirectUri,
    required DateTime expiresAt,
  }) = _CredentialApp;
}

enum CredentialOAuthType {
  google,     // Неактивен
  onedrive,   // Неактивен
  dropbox,    // Активен
  icloud,     // Неактивен
  other,      // Неактивен
}
```

## Хранение

Данные хранятся в **BoxDB** (зашифрованная локальная БД):
- Имя бокса: `credentials`
- Автоматическое шифрование Client ID, Client Secret, Redirect URI
- Ключ шифрования хранится в SecureStorage
- Поддержка backup/restore
- Автоматическая компактификация

## Безопасность

✅ **Шифрование:**
- Все поля credential шифруются AES-GCM
- Client Secret всегда скрыт в UI
- Client ID маскируется при отображении

✅ **Валидация:**
- Обязательные поля
- Проверка дат (не в прошлом)
- Валидация перед сохранением

✅ **Логирование:**
- Все операции логируются
- Секретные данные не попадают в логи
- Ошибки логируются с контекстом

## Расширение

### Добавить новый тип OAuth

1. Добавить в enum:
```dart
enum CredentialOAuthType {
  // ...
  newProvider,
}
```

2. Обновить extension методы в `credential_app.dart`:
```dart
String get name {
  case CredentialOAuthType.newProvider:
    return 'New Provider';
}

String get identifier {
  case CredentialOAuthType.newProvider:
    return 'new_provider';
}

bool get isActive {
  case CredentialOAuthType.newProvider:
    return true; // если активен
}
```

3. Добавить иконку в виджеты (опционально)

4. Запустить кодогенерацию:
```bash
build_runner.bat
```

## TODO

- [ ] Экспорт/импорт credentials
- [ ] Уведомления об истекающих credentials
- [ ] Тестирование OAuth подключений
- [ ] История изменений
- [ ] Поиск/фильтрация
- [ ] Группировка по типам в UI
- [ ] Синхронизация с облаком
