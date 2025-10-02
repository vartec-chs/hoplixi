library;

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/dao/index.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart';
import 'package:hoplixi/hoplixi_store/services/categories_service.dart';
import 'package:hoplixi/hoplixi_store/services/icons_service.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/services/password_service.dart';
import 'package:hoplixi/hoplixi_store/services/tags_service.dart';
import 'package:hoplixi/hoplixi_store/services/totp_service.dart';
import 'dao_providers.dart';
import 'hoplixi_store_providers.dart';

// =============================================================================
// СЕРВИС ПРОВАЙДЕРЫ
// =============================================================================

/// Провайдер для CategoriesService
final categoriesServiceProvider = Provider<CategoriesService>((ref) {
  final categoriesDao = ref.watch(categoriesDaoProvider);

  ref.onDispose(() {
    logInfo(
      'Освобождение ресурсов CategoriesService',
      tag: 'ServicesProviders',
    );
  });

  return CategoriesService(categoriesDao);
});

/// Провайдер для IconsService
final iconsServiceProvider = Provider<IconsService>((ref) {
  final iconsDao = ref.watch(iconsDaoProvider);

  ref.onDispose(() {
    logInfo('Освобождение ресурсов IconsService', tag: 'ServicesProviders');
  });

  return IconsService(iconsDao);
});

/// Провайдер для TagsService
final tagsServiceProvider = Provider<TagsService>((ref) {
  final tagsDao = ref.watch(tagsDaoProvider);

  ref.onDispose(() {
    logInfo('Освобождение ресурсов TagsService', tag: 'ServicesProviders');
  });

  return TagsService(tagsDao);
});

/// Провайдер для PasswordsService
final passwordsServiceProvider = Provider<PasswordService>((ref) {
  final db = ref.watch(hoplixiStoreProvider.notifier);

  ref.onDispose(() {
    logInfo('Освобождение ресурсов PasswordsService', tag: 'ServicesProviders');
  });

  return PasswordService(db.currentDatabase);
});

/// Провайдер для TOTPService

final totpServiceProvider = Provider.autoDispose<TOTPService>((ref) {
  final otpsDao = ref.watch(otpsDaoProvider);
  final categoriesDao = ref.watch(categoriesDaoProvider);

  ref.onDispose(() {
    logInfo('Освобождение ресурсов TOTPService', tag: 'ServicesProviders');
  });

  return TOTPService(otpsDao, categoriesDao);
});

// =============================================================================
// STREAM ПРОВАЙДЕРЫ ДЛЯ КАТЕГОРИЙ
// =============================================================================

/// Stream провайдер для всех категорий
final allCategoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  try {
    final service = ref.watch(categoriesServiceProvider);
    return service.watchAllCategories();
  } catch (e) {
    logError(
      'Ошибка в allCategoriesStreamProvider',
      error: e,
      tag: 'ServicesProviders',
    );
    // Возвращаем пустой поток в случае ошибки
    return Stream.value(<Category>[]);
  }
});

/// Stream провайдер для категорий по типу
final categoriesByTypeStreamProvider =
    StreamProvider.family<List<Category>, CategoryType>((ref, type) {
      try {
        final service = ref.watch(categoriesServiceProvider);
        return service.watchCategoriesByType(type);
      } catch (e) {
        logError(
          'Ошибка в categoriesByTypeStreamProvider',
          error: e,
          tag: 'ServicesProviders',
          data: {'type': type.name},
        );
        return Stream.value(<Category>[]);
      }
    });

/// FutureProvider для получения категории по ID
final categoryByIdProvider = FutureProvider.family<Category?, String>((
  ref,
  id,
) async {
  try {
    final service = ref.watch(categoriesServiceProvider);
    return await service.getCategory(id);
  } catch (e) {
    logError(
      'Ошибка в categoryByIdProvider',
      error: e,
      tag: 'ServicesProviders',
      data: {'id': id},
    );
    return null;
  }
});

/// FutureProvider для поиска категорий
final searchCategoriesProvider = FutureProvider.family<List<Category>, String>((
  ref,
  query,
) async {
  try {
    final service = ref.watch(categoriesServiceProvider);
    return await service.searchCategories(query);
  } catch (e) {
    logError(
      'Ошибка в searchCategoriesProvider',
      error: e,
      tag: 'ServicesProviders',
      data: {'query': query},
    );
    return <Category>[];
  }
});

/// FutureProvider для получения категорий с подсчетом элементов
final categoriesWithItemCountProvider =
    FutureProvider.family<List<CategoryWithItemCount>, CategoryType>((
      ref,
      type,
    ) async {
      try {
        final service = ref.watch(categoriesServiceProvider);
        return await service.getCategoriesWithItemCount(type);
      } catch (e) {
        logError(
          'Ошибка в categoriesWithItemCountProvider',
          error: e,
          tag: 'ServicesProviders',
          data: {'type': type.name},
        );
        return <CategoryWithItemCount>[];
      }
    });

/// FutureProvider для статистики категорий
final categoriesStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  try {
    final service = ref.watch(categoriesServiceProvider);
    return await service.getCategoriesStats();
  } catch (e) {
    logError(
      'Ошибка в categoriesStatsProvider',
      error: e,
      tag: 'ServicesProviders',
    );
    return {'total': 0, 'byType': <String, int>{}};
  }
});

// =============================================================================
// STREAM ПРОВАЙДЕРЫ ДЛЯ ИКОНОК
// =============================================================================

/// Stream провайдер для всех иконок
final allIconsStreamProvider = StreamProvider<List<IconData>>((ref) {
  try {
    final service = ref.watch(iconsServiceProvider);
    return service.watchAllIcons();
  } catch (e) {
    logError(
      'Ошибка в allIconsStreamProvider',
      error: e,
      tag: 'ServicesProviders',
    );
    return Stream.value(<IconData>[]);
  }
});

/// Stream провайдер для иконок по типу
final iconsByTypeStreamProvider =
    StreamProvider.family<List<IconData>, IconType>((ref, type) {
      try {
        final service = ref.watch(iconsServiceProvider);
        return service.watchIconsByType(type);
      } catch (e) {
        logError(
          'Ошибка в iconsByTypeStreamProvider',
          error: e,
          tag: 'ServicesProviders',
          data: {'type': type.name},
        );
        return Stream.value(<IconData>[]);
      }
    });

/// FutureProvider для получения иконки по ID
final iconByIdProvider = FutureProvider.family<IconData?, String>((
  ref,
  id,
) async {
  try {
    final service = ref.watch(iconsServiceProvider);
    return await service.getIcon(id);
  } catch (e) {
    logError(
      'Ошибка в iconByIdProvider',
      error: e,
      tag: 'ServicesProviders',
      data: {'id': id},
    );
    return null;
  }
});

/// FutureProvider для поиска иконок
final searchIconsProvider = FutureProvider.family<List<IconData>, String>((
  ref,
  query,
) async {
  try {
    final service = ref.watch(iconsServiceProvider);
    return await service.searchIcons(query);
  } catch (e) {
    logError(
      'Ошибка в searchIconsProvider',
      error: e,
      tag: 'ServicesProviders',
      data: {'query': query},
    );
    return <IconData>[];
  }
});

/// FutureProvider для статистики иконок
final iconsStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final service = ref.watch(iconsServiceProvider);
    return await service.getIconsStats();
  } catch (e) {
    logError('Ошибка в iconsStatsProvider', error: e, tag: 'ServicesProviders');
    return {
      'total': 0,
      'byType': <String, int>{},
      'totalSize': 0,
      'averageSize': 0,
    };
  }
});

/// FutureProvider для получения крупных иконок
final largeIconsProvider = FutureProvider.family<List<IconWithSize>, int>((
  ref,
  sizeInBytes,
) async {
  try {
    final service = ref.watch(iconsServiceProvider);
    return await service.getLargeIcons(sizeInBytes: sizeInBytes);
  } catch (e) {
    logError(
      'Ошибка в largeIconsProvider',
      error: e,
      tag: 'ServicesProviders',
      data: {'sizeLimit': sizeInBytes},
    );
    return <IconWithSize>[];
  }
});

/// FutureProvider для получения иконок с информацией об использовании
final iconsWithUsageProvider = FutureProvider<List<IconWithUsage>>((ref) async {
  try {
    final service = ref.watch(iconsServiceProvider);
    return await service.getIconsWithUsage();
  } catch (e) {
    logError(
      'Ошибка в iconsWithUsageProvider',
      error: e,
      tag: 'ServicesProviders',
    );
    return <IconWithUsage>[];
  }
});

/// FutureProvider для получения неиспользуемых иконок
final unusedIconsProvider = FutureProvider<List<IconData>>((ref) async {
  try {
    final service = ref.watch(iconsServiceProvider);
    return await service.getUnusedIcons();
  } catch (e) {
    logError(
      'Ошибка в unusedIconsProvider',
      error: e,
      tag: 'ServicesProviders',
    );
    return <IconData>[];
  }
});

// =============================================================================
// ПРОВАЙДЕРЫ ДЛЯ СОСТОЯНИЯ UI
// =============================================================================

/// StateNotifierProvider для управления состоянием создания категории
final createCategoryStateProvider =
    StateNotifierProvider<CreateCategoryNotifier, AsyncValue<void>>((ref) {
      final service = ref.watch(categoriesServiceProvider);
      return CreateCategoryNotifier(service);
    });

/// StateNotifier для создания категории
class CreateCategoryNotifier extends StateNotifier<AsyncValue<void>> {
  final CategoriesService _service;

  CreateCategoryNotifier(this._service) : super(const AsyncValue.data(null));

  Future<bool> createCategory({
    required String name,
    String? description,
    String? iconId,
    required String color,
    required CategoryType type,
  }) async {
    state = const AsyncValue.loading();

    try {
      final result = await _service.createCategory(
        name: name,
        description: description,
        iconId: iconId,
        color: color,
        type: type,
      );

      if (result.success) {
        state = const AsyncValue.data(null);
        logInfo(
          'Категория создана успешно',
          tag: 'CreateCategoryNotifier',
          data: {'name': name, 'categoryId': result.categoryId},
        );
        return true;
      } else {
        state = AsyncValue.error(
          result.message ?? 'Неизвестная ошибка',
          StackTrace.current,
        );
        return false;
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      logError(
        'Ошибка создания категории в UI',
        error: e,
        stackTrace: stackTrace,
        tag: 'CreateCategoryNotifier',
        data: {'name': name},
      );
      return false;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// StateNotifierProvider для управления состоянием создания иконки
final createIconStateProvider =
    StateNotifierProvider<CreateIconNotifier, AsyncValue<void>>((ref) {
      final service = ref.watch(iconsServiceProvider);
      return CreateIconNotifier(service);
    });

/// StateNotifier для создания иконки
class CreateIconNotifier extends StateNotifier<AsyncValue<void>> {
  final IconsService _service;

  CreateIconNotifier(this._service) : super(const AsyncValue.data(null));

  Future<bool> createIcon({
    required String name,
    required IconType type,
    required Uint8List data,
  }) async {
    state = const AsyncValue.loading();

    try {
      final result = await _service.createIcon(
        name: name,
        type: type,
        data: data,
      );

      if (result.success) {
        state = const AsyncValue.data(null);
        logInfo(
          'Иконка создана успешно',
          tag: 'CreateIconNotifier',
          data: {'name': name, 'iconId': result.iconId},
        );
        return true;
      } else {
        state = AsyncValue.error(
          result.message ?? 'Неизвестная ошибка',
          StackTrace.current,
        );
        return false;
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      logError(
        'Ошибка создания иконки в UI',
        error: e,
        stackTrace: stackTrace,
        tag: 'CreateIconNotifier',
        data: {'name': name},
      );
      return false;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

// =============================================================================
// ДОПОЛНИТЕЛЬНЫЕ ПОЛЕЗНЫЕ ПРОВАЙДЕРЫ
// =============================================================================

/// Провайдер для проверки доступности сервисов

/// Провайдер для получения количества категорий каждого типа
final categoriesCountByTypeProvider = FutureProvider<Map<CategoryType, int>>((
  ref,
) async {
  try {
    final stats = await ref.watch(categoriesStatsProvider.future);
    final byTypeMap = stats['byType'] as Map<String, int>? ?? {};

    final result = <CategoryType, int>{};
    for (final type in CategoryType.values) {
      result[type] = byTypeMap[type.name] ?? 0;
    }

    return result;
  } catch (e) {
    logError(
      'Ошибка в categoriesCountByTypeProvider',
      error: e,
      tag: 'ServicesProviders',
    );
    return <CategoryType, int>{};
  }
});

/// Провайдер для получения количества иконок каждого типа
final iconsCountByTypeProvider = FutureProvider<Map<IconType, int>>((
  ref,
) async {
  try {
    final stats = await ref.watch(iconsStatsProvider.future);
    final byTypeMap = stats['byType'] as Map<String, int>? ?? {};

    final result = <IconType, int>{};
    for (final type in IconType.values) {
      result[type] = byTypeMap[type.name] ?? 0;
    }

    return result;
  } catch (e) {
    logError(
      'Ошибка в iconsCountByTypeProvider',
      error: e,
      tag: 'ServicesProviders',
    );
    return <IconType, int>{};
  }
});

/// Провайдер для форматирования размера файлов
final fileFormatterProvider = Provider<String Function(int)>((ref) {
  final service = ref.watch(iconsServiceProvider);
  return service.formatFileSize;
});

// =============================================================================
// АВТООБНОВЛЯЕМЫЕ ПРОВАЙДЕРЫ
// =============================================================================

/// Провайдер для автоматического обновления списка категорий каждые 30 секунд
final autoRefreshCategoriesProvider = StreamProvider<List<Category>>((ref) {
  return Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
    try {
      final service = ref.read(categoriesServiceProvider);
      return await service.getAllCategories();
    } catch (e) {
      logError(
        'Ошибка автообновления категорий',
        error: e,
        tag: 'ServicesProviders',
      );
      return <Category>[];
    }
  });
});

/// Провайдер для автоматического обновления статистики иконок каждую минуту
final autoRefreshIconsStatsProvider = StreamProvider<Map<String, dynamic>>((
  ref,
) {
  return Stream.periodic(const Duration(minutes: 1)).asyncMap((_) async {
    try {
      final service = ref.read(iconsServiceProvider);
      return await service.getIconsStats();
    } catch (e) {
      logError(
        'Ошибка автообновления статистики иконок',
        error: e,
        tag: 'ServicesProviders',
      );
      return {
        'total': 0,
        'byType': <String, int>{},
        'totalSize': 0,
        'averageSize': 0,
      };
    }
  });
});
