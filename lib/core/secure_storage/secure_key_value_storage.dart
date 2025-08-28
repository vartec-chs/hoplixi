import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Интерфейс для безопасного key-value хранилища
abstract class SecureKeyValueStorage {
  /// Инициализация хранилища
  Future<void> initialize();

  /// Записать данные в хранилище
  Future<void> write<T>({
    required String storageKey,
    required String key,
    required T data,
    required Map<String, dynamic> Function(T) toJson,
  });

  /// Прочитать данные из хранилища
  Future<T?> read<T>({
    required String storageKey,
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
  });

  /// Прочитать все данные из файла хранилища
  Future<Map<String, T>> readAll<T>({
    required String storageKey,
    required T Function(Map<String, dynamic>) fromJson,
  });

  /// Удалить ключ из хранилища
  Future<void> delete({required String storageKey, required String key});

  /// Удалить все данные из файла хранилища
  Future<void> deleteAll({required String storageKey});

  /// Удалить весь файл хранилища
  Future<void> deleteStorage({required String storageKey});

  /// Проверить существование ключа
  Future<bool> containsKey({required String storageKey, required String key});

  /// Получить все ключи из файла хранилища
  Future<List<String>> getKeys({required String storageKey});

  /// Очистить кэш (если используется)
  Future<void> clearCache();
}

/// Исключения для работы с хранилищем
class SecureStorageException implements Exception {
  final String message;
  final dynamic originalError;

  const SecureStorageException(this.message, [this.originalError]);

  @override
  String toString() => 'SecureStorageException: $message';
}

class EncryptionException extends SecureStorageException {
  const EncryptionException(super.message, [super.originalError]);
}

class FileAccessException extends SecureStorageException {
  const FileAccessException(super.message, [super.originalError]);
}

class ValidationException extends SecureStorageException {
  const ValidationException(super.message, [super.originalError]);
}
