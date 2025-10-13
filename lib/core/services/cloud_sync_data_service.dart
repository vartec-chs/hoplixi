import 'dart:convert';
import 'dart:io';

import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/model/cloud_sync_data.dart';
import 'package:path/path.dart' as p;

/// Generic result object returned by the service operations
class ServiceResult<T> {
  final bool success;
  final String? message;
  final T? data;

  const ServiceResult._(this.success, this.message, this.data);

  factory ServiceResult.success({T? data, String? message}) {
    return ServiceResult._(true, message, data);
  }

  factory ServiceResult.failure(String message) {
    return ServiceResult._(false, message, null);
  }
}

/// Service that persists cloud sync state in a JSON file
class CloudSyncDataService {
  CloudSyncDataService();

  static const _fileName = 'cloud_sync_data.json';
  static const _tag = 'CloudSyncDataService';
  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

  /// Create a new entry
  Future<ServiceResult<CloudSyncDataItem>> createItem(
    CloudSyncDataItem item,
  ) async {
    try {
      if (item.id.trim().isEmpty) {
        return ServiceResult.failure('Identifier cannot be empty');
      }

      final items = await _readItems();
      if (items.any((existing) => existing.id == item.id)) {
        return ServiceResult.failure(
          'Item with the same identifier already exists',
        );
      }

      final updatedItems = List<CloudSyncDataItem>.from(items)..add(item);
      await _writeItems(updatedItems);

      logInfo('Cloud sync item created', tag: _tag, data: {'id': item.id});

      return ServiceResult.success(data: item);
    } catch (e, stack) {
      logError(
        'Failed to create cloud sync item',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      return ServiceResult.failure('Failed to create cloud sync item');
    }
  }

  /// Read all entries
  Future<ServiceResult<List<CloudSyncDataItem>>> getItems() async {
    try {
      final items = await _readItems();
      return ServiceResult.success(data: items);
    } catch (e, stack) {
      logError(
        'Failed to read cloud sync items',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      return ServiceResult.failure('Failed to read cloud sync items');
    }
  }

  /// Read entry by id
  Future<ServiceResult<CloudSyncDataItem>> getItem(String id) async {
    try {
      final items = await _readItems();

      CloudSyncDataItem? found;
      for (final existing in items) {
        if (existing.id == id) {
          found = existing;
          break;
        }
      }

      if (found == null) {
        return ServiceResult.failure('Item not found');
      }

      return ServiceResult.success(data: found);
    } catch (e, stack) {
      logError(
        'Failed to read cloud sync item',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      return ServiceResult.failure('Failed to read cloud sync item');
    }
  }

  /// Update an existing entry
  Future<ServiceResult<CloudSyncDataItem>> updateItem(
    CloudSyncDataItem item,
  ) async {
    try {
      final items = await _readItems();
      final index = items.indexWhere((existing) => existing.id == item.id);

      if (index == -1) {
        return ServiceResult.failure('Item not found');
      }

      final updatedItems = List<CloudSyncDataItem>.from(items);
      updatedItems[index] = item;
      await _writeItems(updatedItems);

      logInfo('Cloud sync item updated', tag: _tag, data: {'id': item.id});

      return ServiceResult.success(data: item);
    } catch (e, stack) {
      logError(
        'Failed to update cloud sync item',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      return ServiceResult.failure('Failed to update cloud sync item');
    }
  }

  /// Delete entry by id
  Future<ServiceResult<void>> deleteItem(String id) async {
    try {
      final items = await _readItems();
      final updatedItems = items.where((item) => item.id != id).toList();

      if (updatedItems.length == items.length) {
        return ServiceResult.failure('Item not found');
      }

      await _writeItems(updatedItems);

      logInfo('Cloud sync item deleted', tag: _tag, data: {'id': id});

      return ServiceResult.success();
    } catch (e, stack) {
      logError(
        'Failed to delete cloud sync item',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      return ServiceResult.failure('Failed to delete cloud sync item');
    }
  }

  /// Find items by name (case-insensitive partial match)
  Future<ServiceResult<List<CloudSyncDataItem>>> findByName(String name) async {
    try {
      final items = await _readItems();
      final query = name.toLowerCase();
      final found = items
          .where((item) => item.name.toLowerCase().contains(query))
          .toList();

      return ServiceResult.success(data: found);
    } catch (e, stack) {
      logError(
        'Failed to find cloud sync items by name',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      return ServiceResult.failure('Failed to find cloud sync items by name');
    }
  }

  /// Find items by path (case-insensitive partial match)
  Future<ServiceResult<List<CloudSyncDataItem>>> findByPath(String path) async {
    try {
      final items = await _readItems();
      final query = path.toLowerCase();
      final found = items
          .where((item) => item.path.toLowerCase().contains(query))
          .toList();

      return ServiceResult.success(data: found);
    } catch (e, stack) {
      logError(
        'Failed to find cloud sync items by path',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      return ServiceResult.failure('Failed to find cloud sync items by path');
    }
  }

  Future<List<CloudSyncDataItem>> _readItems() async {
    final file = await _getStorageFile();

    if (!await file.exists()) {
      return [];
    }

    if (await file.length() == 0) {
      return [];
    }

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('JSON root is not a list');
    }

    final items = <CloudSyncDataItem>[];
    for (final entry in decoded) {
      if (entry is Map<String, dynamic>) {
        items.add(CloudSyncDataItem.fromJson(entry));
      } else if (entry is Map) {
        items.add(CloudSyncDataItem.fromJson(Map<String, dynamic>.from(entry)));
      } else {
        throw const FormatException('List entry is not an object');
      }
    }

    return items;
  }

  Future<void> _writeItems(List<CloudSyncDataItem> items) async {
    final file = await _getStorageFile(createIfMissing: true);
    final jsonList = items.map((item) => item.toJson()).toList();
    final payload = _encoder.convert(jsonList);
    await file.writeAsString(payload, flush: true);
  }

  Future<File> _getStorageFile({bool createIfMissing = false}) async {
    final basePath = await AppPaths.appStoragePath;
    final file = File(p.join(basePath, _fileName));

    if (createIfMissing && !await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('[]');
    }

    return file;
  }
}
