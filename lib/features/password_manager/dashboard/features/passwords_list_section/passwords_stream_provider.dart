import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/models/password_filter.dart';
import 'package:hoplixi/hoplixi_store/providers.dart';
import '../filter_section/filter_section_controller.dart';

/// Reactive StreamProvider для отслеживания списка паролей с автоматической
/// фильтрацией при изменении фильтров
///
/// Этот провайдер использует современный реактивный подход Riverpod:
/// - Автоматически подписывается на изменения фильтра
/// - Переключает поток данных при изменении фильтра
/// - Возвращает AsyncValue<List<CardPasswordDto>> для удобной обработки состояний
final filteredPasswordsStreamProvider =
    StreamProvider.autoDispose<List<CardPasswordDto>>((ref) async* {
      logDebug('Инициализация filteredPasswordsStreamProvider');

      // Получаем сервис паролей
      final passwordService = ref.read(passwordsServiceProvider);

      // Переменная для хранения текущей подписки на stream
      StreamSubscription<List<CardPasswordDto>>? currentSubscription;

      // Контроллер для управления собственным потоком
      final streamController = StreamController<List<CardPasswordDto>>();

      // Отменяем подписку и закрываем контроллер при dispose
      ref.onDispose(() {
        logDebug('Disposing filteredPasswordsStreamProvider');
        currentSubscription?.cancel();
        streamController.close();
      });

      // Функция для переключения на новый поток с фильтром
      void switchToFilteredStream(PasswordFilter filter) {
        logDebug('Переключение на новый фильтр: $filter');

        // Отменяем предыдущую подписку
        currentSubscription?.cancel();

        try {
          // Подписываемся на отфильтрованный поток из сервиса
          final filteredStream = passwordService.watchFilteredPasswords(filter);

          currentSubscription = filteredStream.listen(
            (passwords) {
              logDebug('Получено ${passwords.length} паролей из stream');
              if (!streamController.isClosed) {
                streamController.add(passwords);
              }
            },
            onError: (error, stackTrace) {
              logError(
                'Ошибка в filteredPasswordsStreamProvider',
                error: error,
                stackTrace: stackTrace,
              );
              if (!streamController.isClosed) {
                streamController.addError(error, stackTrace);
              }
            },
          );
        } catch (e, stackTrace) {
          logError(
            'Ошибка при создании stream в filteredPasswordsStreamProvider',
            error: e,
            stackTrace: stackTrace,
          );
          if (!streamController.isClosed) {
            streamController.addError(e, stackTrace);
          }
        }
      }

      // Слушаем изменения фильтра и автоматически переключаем поток
      ref.listen(
        currentPasswordFilterProvider,
        (previous, next) {
          logDebug('Фильтр изменился с $previous на $next');
          switchToFilteredStream(next);
        },
        fireImmediately: true, // Сразу применяем текущий фильтр
      );

      // Возвращаем наш контролируемый поток
      yield* streamController.stream;
    });

/// Reactive provider для получения только списка паролей из AsyncValue
final passwordsListProvider = Provider.autoDispose<List<CardPasswordDto>>((
  ref,
) {
  final asyncPasswords = ref.watch(filteredPasswordsStreamProvider);

  return asyncPasswords.when(
    data: (passwords) => passwords,
    loading: () => <CardPasswordDto>[],
    error: (_, __) => <CardPasswordDto>[],
  );
});

/// Provider для проверки состояния загрузки
final isPasswordsLoadingProvider = Provider.autoDispose<bool>((ref) {
  final asyncPasswords = ref.watch(filteredPasswordsStreamProvider);
  return asyncPasswords.isLoading;
});

/// Provider для получения ошибки загрузки
final passwordsErrorProvider = Provider.autoDispose<Object?>((ref) {
  final asyncPasswords = ref.watch(filteredPasswordsStreamProvider);
  return asyncPasswords.error;
});

/// Provider для проверки состояния обновления (refreshing)
final isPasswordsRefreshingProvider = Provider.autoDispose<bool>((ref) {
  final asyncPasswords = ref.watch(filteredPasswordsStreamProvider);
  return asyncPasswords.isRefreshing;
});

/// Provider для получения общего количества паролей
final passwordsTotalCountProvider = Provider.autoDispose<int>((ref) {
  final passwords = ref.watch(passwordsListProvider);
  return passwords.length;
});

/// Provider для проверки наличия данных
final hasPasswordsDataProvider = Provider.autoDispose<bool>((ref) {
  final asyncPasswords = ref.watch(filteredPasswordsStreamProvider);
  return asyncPasswords.hasValue;
});

/// Actions provider для операций с паролями
/// Содержит методы для выполнения операций без прямого управления состоянием
final passwordsActionsProvider = Provider.autoDispose(
  (ref) => PasswordsActions(ref),
);

class PasswordsActions {
  final Ref _ref;

  const PasswordsActions(this._ref);

  /// Обновление списка паролей (pull-to-refresh)
  Future<void> refreshPasswords() async {
    logDebug('Запуск refreshPasswords');

    // Инвалидируем провайдер, что приведет к перезапуску stream
    _ref.invalidate(filteredPasswordsStreamProvider);
  }

  /// Переключение избранного состояния пароля
  Future<void> toggleFavorite(String passwordId) async {
    try {
      logDebug('Переключение избранного для пароля: $passwordId');

      // Получаем текущий список паролей
      final currentPasswords = _ref.read(passwordsListProvider);
      final passwordIndex = currentPasswords.indexWhere(
        (p) => p.id == passwordId,
      );

      if (passwordIndex == -1) {
        logError('Пароль с ID $passwordId не найден в текущем списке');
        return;
      }

      final password = currentPasswords[passwordIndex];
      final newFavoriteState = !password.isFavorite;

      // Выполняем обновление через сервис
      final passwordService = _ref.read(passwordsServiceProvider);
      final result = await passwordService.updatePassword(
        UpdatePasswordDto(id: passwordId, isFavorite: newFavoriteState),
      );

      if (!result.success) {
        logError('Ошибка при обновлении избранного: ${result.message}');
        // При использовании StreamProvider обновление происходит автоматически
        // через отслеживание изменений в базе данных
      } else {
        logDebug('Избранное успешно обновлено для пароля: $passwordId');
      }
    } catch (e, stackTrace) {
      logError(
        'Ошибка при переключении избранного',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Удаление пароля
  Future<bool> deletePassword(String passwordId) async {
    try {
      logDebug('Удаление пароля: $passwordId');

      final passwordService = _ref.read(passwordsServiceProvider);
      final result = await passwordService.deletePassword(passwordId);

      if (!result.success) {
        logError('Ошибка при удалении пароля: ${result.message}');
        return false;
      }

      logDebug('Пароль успешно удален: $passwordId');
      // При использовании StreamProvider обновление происходит автоматически
      return true;
    } catch (e, stackTrace) {
      logError('Ошибка при удалении пароля', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Поиск паролей по запросу (обновляет фильтр)
  void searchPasswords(String query) {
    logDebug('Поиск паролей по запросу: "$query"');

    final filterController = _ref.read(
      filterSectionControllerProvider.notifier,
    );
    filterController.updateSearchQuery(query);
  }

  /// Получение пароля по ID
  Future<String> getPasswordById(String id) async {
    try {
      final passwordService = _ref.read(passwordsServiceProvider);
      final result = await passwordService.getPasswordById(id);

      if (result.success && result.data != null) {
        return result.data!;
      }

      logError('Ошибка при получении пароля: ${result.message}');
      return '';
    } catch (e, stackTrace) {
      logError(
        'Ошибка при получении пароля по ID',
        error: e,
        stackTrace: stackTrace,
      );
      return '';
    }
  }

  /// Получение URL по ID
  Future<String> getUrlById(String id) async {
    try {
      final passwordService = _ref.read(passwordsServiceProvider);
      final result = await passwordService.getPasswordUrlById(id);

      if (result.success && result.data != null) {
        return result.data!;
      }

      logError('Ошибка при получении URL: ${result.message}');
      return '';
    } catch (e, stackTrace) {
      logError(
        'Ошибка при получении URL по ID',
        error: e,
        stackTrace: stackTrace,
      );
      return '';
    }
  }

  /// Получение логина по ID
  Future<String> getLoginById(String id) async {
    try {
      final passwordService = _ref.read(passwordsServiceProvider);
      final result = await passwordService.getPasswordLoginOrEmailById(id);

      if (result.success && result.data != null) {
        return result.data!;
      }

      logError('Ошибка при получении логина: ${result.message}');
      return '';
    } catch (e, stackTrace) {
      logError(
        'Ошибка при получении логина по ID',
        error: e,
        stackTrace: stackTrace,
      );
      return '';
    }
  }
}

/// Вспомогательный provider для уведомления об изменениях паролей
/// (сохранен для обратной совместимости)
final passwordChangeNotifierProvider = Provider.autoDispose<void Function()>((
  ref,
) {
  return () {
    logDebug(
      'Уведомление об изменении пароля - обновление через StreamProvider происходит автоматически',
    );
    // При использовании reactive StreamProvider явные уведомления не нужны
    // Изменения отслеживаются автоматически через database streams
  };
});
