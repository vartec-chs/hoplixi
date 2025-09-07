/// Индексный файл для всех провайдеров базы данных
///
/// Этот файл экспортирует все провайдеры, связанные с базой данных Hoplixi Store.
/// Включает в себя:
/// - Основные провайдеры для менеджера и состояния базы данных
/// - Провайдеры для всех DAO (Data Access Objects)
/// - Stream провайдеры для реактивных данных
/// - Семейные провайдеры для параметризованных запросов
/// - Статистические провайдеры
///
/// Использование:
/// ```dart
/// import 'package:hoplixi/hoplixi_store/providers_index.dart';
///
/// // В виджете
/// final passwords = ref.watch(allPasswordsStreamProvider);
/// final dao = ref.read(passwordsDaoProvider);
/// ```
library;

export 'hoplixi_store_providers.dart';

// =============================================================================
// ДОКУМЕНТАЦИЯ ПО ИСПОЛЬЗОВАНИЮ ПРОВАЙДЕРОВ
// =============================================================================

/// ## Основные провайдеры
/// 
/// ### hoplixiStoreManagerProvider
/// Основной провайдер для менеджера базы данных. Обеспечивает создание,
/// открытие и закрытие базы данных.
/// 
/// ### databaseStateProvider  
/// Провайдер состояния базы данных. Позволяет отслеживать текущее состояние
/// (открыта/закрыта/загружается/ошибка) и получать информацию о БД.
/// 
/// ## DAO Провайдеры
/// 
/// Все DAO провайдеры проверяют что база данных открыта перед предоставлением доступа:
/// 
/// - `passwordsDaoProvider` - для работы с паролями
/// - `notesDaoProvider` - для работы с заметками  
/// - `categoriesDaoProvider` - для работы с категориями
/// - `tagsDaoProvider` - для работы с тегами
/// - `totpsDaoProvider` - для работы с TOTP кодами
/// - `iconsDaoProvider` - для работы с иконками
/// - `attachmentsDaoProvider` - для работы с вложениями
/// - `passwordTagsDaoProvider` - для связей пароль-тег
/// - `noteTagsDaoProvider` - для связей заметка-тег  
/// - `totpTagsDaoProvider` - для связей TOTP-тег
/// 
/// ## Stream Провайдеры
/// 
/// Для реактивного отслеживания изменений данных:
/// 
/// - `allPasswordsStreamProvider` - все пароли
/// - `favoritePasswordsStreamProvider` - избранные пароли
/// - `allNotesStreamProvider` - все заметки
/// - `favoriteNotesStreamProvider` - избранные заметки
/// - `pinnedNotesStreamProvider` - закрепленные заметки
/// - `allCategoriesStreamProvider` - все категории
/// - `allTagsStreamProvider` - все теги
/// - `allTotpsStreamProvider` - все TOTP
/// - `favoriteTotpsStreamProvider` - избранные TOTP
/// 
/// ## Семейные провайдеры
/// 
/// Для параметризованных запросов:
/// 
/// - `passwordsByCategoryProvider.call(categoryId)` - пароли по категории
/// - `notesByCategoryProvider.call(categoryId)` - заметки по категории  
/// - `totpsByCategoryProvider.call(categoryId)` - TOTP по категории
/// - `categoriesByTypeProvider.call(type)` - категории по типу
/// - `tagsByTypeProvider.call(type)` - теги по типу
/// - `passwordTagsProvider.call(passwordId)` - теги пароля
/// - `noteTagsProvider.call(noteId)` - теги заметки
/// - `totpTagsProvider.call(totpId)` - теги TOTP
/// 
/// ## Статистические провайдеры
/// 
/// Для получения статистики:
/// 
/// - `passwordsStatsProvider` - статистика паролей
/// - `notesStatsProvider` - статистика заметок
/// - `categoriesStatsProvider` - статистика категорий
/// 
/// ## Примеры использования
/// 
/// ### Создание новой базы данных
/// ```dart
/// final notifier = ref.read(databaseStateProvider.notifier);
/// await notifier.createDatabase(CreateDatabaseDto(
///   name: 'My Database',
///   masterPassword: 'secure_password',
/// ));
/// ```
/// 
/// ### Открытие существующей базы данных
/// ```dart
/// final notifier = ref.read(databaseStateProvider.notifier);
/// await notifier.openDatabase(OpenDatabaseDto(
///   path: '/path/to/database.hdb',
///   masterPassword: 'password',
/// ));
/// ```
/// 
/// ### Работа с данными
/// ```dart
/// // Получение DAO
/// final passwordsDao = ref.read(passwordsDaoProvider);
/// 
/// // Создание нового пароля
/// await passwordsDao.createPassword(CreatePasswordDto(
///   name: 'GitHub',
///   password: 'secret123',
///   url: 'https://github.com',
/// ));
/// 
/// // Отслеживание изменений
/// Widget build(BuildContext context) {
///   final passwordsAsync = ref.watch(allPasswordsStreamProvider);
///   
///   return passwordsAsync.when(
///     data: (passwords) => ListView.builder(
///       itemCount: passwords.length,
///       itemBuilder: (context, index) => ListTile(
///         title: Text(passwords[index].name),
///       ),
///     ),
///     loading: () => CircularProgressIndicator(),
///     error: (error, stack) => Text('Error: $error'),
///   );
/// }
/// ```
/// 
/// ### Использование семейных провайдеров
/// ```dart
/// // Пароли конкретной категории
/// final categoryPasswordsAsync = ref.watch(
///   passwordsByCategoryProvider('category-id'),
/// );
/// 
/// // Теги конкретного пароля
/// final passwordTagsAsync = ref.watch(
///   passwordTagsProvider('password-id'),
/// );
/// ```
/// 
/// ### Обработка ошибок
/// ```dart
/// Widget build(BuildContext context) {
///   final state = ref.watch(databaseStateProvider);
///   
///   if (state.hasError) {
///     return ErrorWidget(state.error.toString());
///   }
///   
///   if (!state.isOpen) {
///     return DatabaseClosedWidget();
///   }
///   
///   // База данных открыта, можно использовать провайдеры
///   return MainAppWidget();
/// }
/// ```
