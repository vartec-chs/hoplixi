import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart';
import 'package:hoplixi/hoplixi_store/providers.dart';
import 'package:hoplixi/hoplixi_store/services/password_service.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/models/password_filter.dart';
import '../filter_section/filter_section_controller.dart';

/// Состояние списка паролей
@immutable
class PasswordsListState {
  /// Список отфильтрованных паролей
  final List<CardPasswordDto> passwords;

  /// Загрузка данных в процессе
  final bool isLoading;

  /// Есть ли ошибка
  final String? error;

  /// Есть ли еще данные для подгрузки (пагинация)
  final bool hasMore;

  /// Количество загруженных паролей
  final int totalCount;

  const PasswordsListState({
    required this.passwords,
    required this.isLoading,
    this.error,
    required this.hasMore,
    required this.totalCount,
  });

  PasswordsListState copyWith({
    List<CardPasswordDto>? passwords,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? totalCount,
  }) {
    return PasswordsListState(
      passwords: passwords ?? this.passwords,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PasswordsListState &&
        listEquals(other.passwords, passwords) &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.hasMore == hasMore &&
        other.totalCount == totalCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(passwords),
      isLoading,
      error,
      hasMore,
      totalCount,
    );
  }
}

/// Контроллер для управления списком паролей
class PasswordsListController extends Notifier<PasswordsListState> {
  PasswordService? _passwordService;
  StreamSubscription<List<CardPasswordDto>>? _passwordsStreamSubscription;

  /// Размер страницы для пагинации
  static const int _pageSize = 10;

  @override
  PasswordsListState build() {
    _passwordService = ref.read(passwordsServiceProvider);

    // Очищаем подписку при dispose
    ref.onDispose(() {
      _passwordsStreamSubscription?.cancel();
    });

    // Слушаем изменения фильтра и автоматически переподписываемся на новый stream
    ref.listen(currentPasswordFilterProvider, (previous, next) {
      if (previous != next) {
        _watchPasswordsWithFilter(next);
      }
    });

    // Инициализируем пустым состоянием
    final initialState = const PasswordsListState(
      passwords: [],
      isLoading: true,
      hasMore: true,
      totalCount: 0,
    );

    // Начинаем отслеживание с текущим фильтром
    final currentFilter = ref.read(currentPasswordFilterProvider);
    _watchPasswordsWithFilter(currentFilter);

    return initialState;
  }

  /// Отслеживание паролей с конкретным фильтром через stream из DAO
  void _watchPasswordsWithFilter(PasswordFilter filter) {
    // Отменяем предыдущую подписку
    _passwordsStreamSubscription?.cancel();

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Подписываемся на stream отфильтрованных паролей из DAO
      final passwordsStream = _passwordService!.watchFilteredPasswords(filter);

      _passwordsStreamSubscription = passwordsStream.listen(
        (passwords) {
          // Обновляем состояние при получении новых данных
          state = state.copyWith(
            passwords: passwords,
            isLoading: false,
            error: null,
            hasMore: passwords.length >= _pageSize,
            totalCount: passwords.length,
          );
        },
        onError: (error, stackTrace) {
          logError(
            'Ошибка при отслеживании паролей через stream',
            error: error,
            stackTrace: stackTrace,
          );
          state = state.copyWith(
            isLoading: false,
            error: 'Ошибка при загрузке паролей: $error',
          );
        },
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка при настройке stream паролей',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка при настройке отслеживания паролей: $e',
      );
    }
  }

  /// Перезагрузка паролей с текущим фильтром
  /// Полезно для обновления после ошибок
  Future<void> reloadPasswords() async {
    final filter = ref.read(currentPasswordFilterProvider);
    _watchPasswordsWithFilter(filter);
  }

  /// Обновление списка паролей (pull-to-refresh)
  Future<void> refreshPasswords() async {
    await reloadPasswords();
  }

  /// Переключение избранного состояния пароля
  Future<void> toggleFavorite(String passwordId) async {
    try {
      // Находим пароль в текущем списке
      final passwordIndex = state.passwords.indexWhere(
        (p) => p.id == passwordId,
      );
      if (passwordIndex == -1) return;

      final password = state.passwords[passwordIndex];
      final newFavoriteState = !password.isFavorite;

      // Оптимистично обновляем UI
      final updatedPasswords = [...state.passwords];
      updatedPasswords[passwordIndex] = password.copyWith(
        isFavorite: newFavoriteState,
      );
      state = state.copyWith(passwords: updatedPasswords);

      // Обновляем в базе данных
      final result = await _passwordService!.updatePassword(
        UpdatePasswordDto(id: passwordId, isFavorite: newFavoriteState),
      );

      if (!result.success) {
        // Откатываем изменения при ошибке
        updatedPasswords[passwordIndex] = password;
        state = state.copyWith(passwords: updatedPasswords);
        logError('Ошибка при обновлении избранного: ${result.message}');
      }
    } catch (e, stackTrace) {
      // Перезагружаем список при критической ошибке
      await refreshPasswords();
      logError(
        'Ошибка при переключении избранного',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Удаление пароля
  Future<void> deletePassword(String passwordId) async {
    try {
      // Оптимистично удаляем из UI
      final updatedPasswords = state.passwords
          .where((p) => p.id != passwordId)
          .toList();
      final previousPasswords = state.passwords;

      state = state.copyWith(
        passwords: updatedPasswords,
        totalCount: state.totalCount - 1,
      );

      // Удаляем из базы данных
      final result = await _passwordService!.deletePassword(passwordId);

      if (!result.success) {
        // Откатываем изменения при ошибке
        state = state.copyWith(
          passwords: previousPasswords,
          totalCount: state.totalCount + 1,
        );
        logError('Ошибка при удалении пароля: ${result.message}');
      }
    } catch (e, stackTrace) {
      // Перезагружаем список при критической ошибке
      await refreshPasswords();
      logError('Ошибка при удалении пароля', error: e, stackTrace: stackTrace);
    }
  }

  /// Поиск паролей по запросу
  Future<void> searchPasswords(String query) async {
    final filterController = ref.read(filterSectionControllerProvider.notifier);
    filterController.updateSearchQuery(query);
  }

  /// Уведомление об успешном создании или изменении пароля
  /// При использовании stream обновление происходит автоматически
  void notifyPasswordChanged() {
    // При использовании stream обновление происходит автоматически
    logDebug('Пароль изменен, stream автоматически обновит список');
  }

  /// Установка сервиса базы данных (для внешнего использования)
  void setHoplixiStore(HoplixiStore store) {
    _passwordService = PasswordService(store);
  }

  Future<String> getPasswordById(String id) async {
    final result = await _passwordService!.getPasswordById(id);
    if (result.success && result.data != null) {
      return result.data!;
    }

    logError('Ошибка при получении пароля: ${result.message}');

    return '';
  }

  // get url by id
  Future<String> getUrlById(String id) async {
    final result = await _passwordService!.getPasswordUrlById(id);
    if (result.success && result.data != null) return result.data!;

    logError('Ошибка при получении пароля: ${result.message}');

    return '';
  }

  // get login by id
  Future<String> getLoginById(String id) async {
    final result = await _passwordService!.getPasswordLoginOrEmailById(id);
    if (result.success) return result.data!;

    logError('Ошибка при получении пароля: ${result.message}');

    return '';
  }

  /// Очистка ошибки
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider для контроллера списка паролей
final passwordsListControllerProvider =
    NotifierProvider<PasswordsListController, PasswordsListState>(
      PasswordsListController.new,
    );

/// Provider для получения только списка паролей
final passwordsListProvider = Provider<List<CardPasswordDto>>((ref) {
  return ref.watch(
    passwordsListControllerProvider.select((state) => state.passwords),
  );
});

/// Provider для проверки состояния загрузки
final isPasswordsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(
    passwordsListControllerProvider.select((state) => state.isLoading),
  );
});

/// Provider для получения ошибки
final passwordsErrorProvider = Provider<String?>((ref) {
  return ref.watch(
    passwordsListControllerProvider.select((state) => state.error),
  );
});

/// Provider для проверки наличия дополнительных данных
final hasMorePasswordsProvider = Provider<bool>((ref) {
  return ref.watch(
    passwordsListControllerProvider.select((state) => state.hasMore),
  );
});

/// Provider для общего количества паролей
final passwordsTotalCountProvider = Provider<int>((ref) {
  return ref.watch(
    passwordsListControllerProvider.select((state) => state.totalCount),
  );
});

/// Provider для уведомления об изменениях паролей
/// Используется для обновления списка после создания/изменения пароля
final passwordChangeNotifierProvider = Provider<void Function()>((ref) {
  return () {
    ref.read(passwordsListControllerProvider.notifier).notifyPasswordChanged();
  };
});
