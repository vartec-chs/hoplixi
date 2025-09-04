// Database History Service API Reference

/// Основные компоненты
export '../models/database_entry.dart';
export '../services/database_history_service.dart';

/// Модель записи истории базы данных
/// 
/// DatabaseEntry:
/// - path: String - путь к файлу БД
/// - name: String - название БД  
/// - description: String? - описание (опционально)
/// - masterPassword: String? - пароль (если saveMasterPassword = true)
/// - saveMasterPassword: bool - флаг сохранения пароля
/// - lastAccessed: DateTime? - дата последнего доступа
/// - createdAt: DateTime? - дата создания записи

/// Основные методы DatabaseHistoryService:
/// 
/// - recordDatabaseAccess() - записать доступ к БД
/// - getAllHistory() - получить всю историю
/// - getEntryByPath() - получить запись по пути
/// - removeEntry() - удалить запись
/// - clearHistory() - очистить всю историю
/// - getEntriesWithSavedPasswords() - получить записи с паролями
/// - updateDatabaseInfo() - обновить информацию о БД
/// - getHistoryStats() - получить статистику
/// - dispose() - освободить ресурсы

/// Интеграция с HoplixiStoreManager:
/// 
/// - historyService: DatabaseHistoryService - доступ к сервису
/// - getDatabaseHistory() - получить историю
/// - getDatabaseHistoryEntry() - получить запись
/// - removeDatabaseHistoryEntry() - удалить запись  
/// - clearDatabaseHistory() - очистить историю
/// - getDatabaseHistoryStats() - статистика
/// - getDatabaseHistoryWithSavedPasswords() - записи с паролями
/// 
/// Автоматическая запись в историю при:
/// - createDatabase() - создании БД
/// - openDatabase() - открытии БД
