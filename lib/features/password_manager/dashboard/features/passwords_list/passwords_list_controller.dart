import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/features/filter_section/filter_section_barrel.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart';
import 'package:hoplixi/hoplixi_store/models/password_filter.dart';
import 'package:hoplixi/hoplixi_store/providers.dart';
import 'package:hoplixi/hoplixi_store/services/password_service.dart';

/// Состояние списка паролей
/// Теперь используется с AsyncValue для автоматической обработки загрузки и ошибок
@immutable
class PasswordsListState {
  /// Список отфильтрованных паролей
  final List<CardPasswordDto> passwords;

  /// Есть ли еще данные для подгрузки (пагинация)
  final bool hasMore;

  /// Количество загруженных паролей
  final int totalCount;

  const PasswordsListState({
    required this.passwords,
    required this.hasMore,
    required this.totalCount,
  });

  PasswordsListState copyWith({
    List<CardPasswordDto>? passwords,
    bool? hasMore,
    int? totalCount,
  }) {
    return PasswordsListState(
      passwords: passwords ?? this.passwords,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PasswordsListState &&
        listEquals(other.passwords, passwords) &&
        other.hasMore == hasMore &&
        other.totalCount == totalCount;
  }

  @override
  int get hashCode {
    return Object.hash(Object.hashAll(passwords), hasMore, totalCount);
  }
}

/// Контроллер для управления списком паролей
class PasswordsListController extends AsyncNotifier<PasswordsListState> {
  PasswordService? _passwordService;

  /// Размер страницы для пагинации
  static const int _pageSize = 10;

  @override
  Future<PasswordsListState> build() async {
    // Слушаем изменения фильтра и автоматически обновляем список
    ref.listen(currentPasswordFilterProvider, (previous, next) {
      if (previous != next) {
        _loadPasswordsWithFilter(next);
      }
    });

    _passwordService = ref.read(passwordsServiceProvider);

    // Загружаем начальные данные
    final filter = ref.read(currentPasswordFilterProvider);
    return await _loadPasswordsWithFilter(filter);
  }

  /// Загрузка паролей с конкретным фильтром
  Future<PasswordsListState> _loadPasswordsWithFilter(
    PasswordFilter filter,
  ) async {
    try {
      final result = await _passwordService!.getFilteredPasswords(
        filter.copyWith(
          limit: _pageSize,
          offset: 0, // Сбрасываем офсет при новом фильтре
        ),
      );

      if (result.success) {
        final passwords = result.data ?? [];
        return PasswordsListState(
          passwords: passwords,
          hasMore: passwords.length == _pageSize,
          totalCount: passwords.length,
        );
      } else {
        logError('Ошибка загрузки паролей: ${result.message}');
        throw Exception(result.message ?? 'Ошибка при загрузке паролей');
      }
    } catch (e, stackTrace) {
      logError(
        'Неожиданная ошибка при загрузке паролей',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Загрузка паролей с текущим фильтром
  Future<void> loadPasswords() async {
    state = const AsyncLoading();
    final filter = ref.read(currentPasswordFilterProvider);

    try {
      final newState = await _loadPasswordsWithFilter(filter);
      state = AsyncData(newState);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  /// Загрузка дополнительных паролей для пагинации
  Future<void> loadMorePasswords() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore) return;

    try {
      final filter = ref.read(currentPasswordFilterProvider);
      final result = await _passwordService!.getFilteredPasswords(
        filter.copyWith(
          limit: _pageSize,
          offset: currentState.passwords.length,
        ),
      );

      if (result.success) {
        final newPasswords = result.data ?? [];
        final allPasswords = [...currentState.passwords, ...newPasswords];

        state = AsyncData(
          currentState.copyWith(
            passwords: allPasswords,
            hasMore: newPasswords.length == _pageSize,
            totalCount: allPasswords.length,
          ),
        );
      } else {
        logError('Ошибка загрузки дополнительных паролей: ${result.message}');
        throw Exception(
          result.message ?? 'Ошибка загрузки дополнительных паролей',
        );
      }
    } catch (e, stackTrace) {
      logError(
        'Неожиданная ошибка при загрузке дополнительных паролей',
        error: e,
        stackTrace: stackTrace,
      );
      // Не меняем состояние при ошибке пагинации
    }
  }

  /// Обновление списка паролей (pull-to-refresh)
  Future<void> refreshPasswords() async {
    await loadPasswords();
  }

  /// Переключение избранного состояния пароля
  Future<void> toggleFavorite(String passwordId) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      // Находим пароль в текущем списке
      final passwordIndex = currentState.passwords.indexWhere(
        (p) => p.id == passwordId,
      );
      if (passwordIndex == -1) return;

      final password = currentState.passwords[passwordIndex];
      final newFavoriteState = !password.isFavorite;

      // Оптимистично обновляем UI
      final updatedPasswords = [...currentState.passwords];
      updatedPasswords[passwordIndex] = password.copyWith(
        isFavorite: newFavoriteState,
      );

      state = AsyncData(currentState.copyWith(passwords: updatedPasswords));

      // Обновляем в базе данных
      final result = await _passwordService!.updatePassword(
        UpdatePasswordDto(id: passwordId, isFavorite: newFavoriteState),
      );

      if (!result.success) {
        // Откатываем изменения при ошибке
        updatedPasswords[passwordIndex] = password;
        state = AsyncData(currentState.copyWith(passwords: updatedPasswords));
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
    final currentState = state.value;
    if (currentState == null) return;

    try {
      // Оптимистично удаляем из UI
      final updatedPasswords = currentState.passwords
          .where((p) => p.id != passwordId)
          .toList();
      final previousState = currentState;

      state = AsyncData(
        currentState.copyWith(
          passwords: updatedPasswords,
          totalCount: currentState.totalCount - 1,
        ),
      );

      // Удаляем из базы данных
      final result = await _passwordService!.deletePassword(passwordId);

      if (!result.success) {
        // Откатываем изменения при ошибке
        state = AsyncData(previousState);
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
  void notifyPasswordChanged() {
    // Обновляем список после изменений
    loadPasswords();
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

    logError('Ошибка при получении URL: ${result.message}');
    return '';
  }

  // get login by id
  Future<String> getLoginById(String id) async {
    final result = await _passwordService!.getPasswordLoginOrEmailById(id);
    if (result.success) return result.data!;

    logError('Ошибка при получении логина: ${result.message}');
    return '';
  }
}

/// Provider для контроллера списка паролей
final passwordsListControllerProvider =
    AsyncNotifierProvider<PasswordsListController, PasswordsListState>(
      PasswordsListController.new,
    );

/// Provider для получения только списка паролей
final passwordsListProvider = Provider<List<CardPasswordDto>>((ref) {
  final asyncState = ref.watch(passwordsListControllerProvider);
  return asyncState.value?.passwords ?? [];
});

/// Provider для проверки состояния загрузки
final isPasswordsLoadingProvider = Provider<bool>((ref) {
  final asyncState = ref.watch(passwordsListControllerProvider);
  return asyncState.isLoading;
});

/// Provider для получения ошибки
final passwordsErrorProvider = Provider<String?>((ref) {
  final asyncState = ref.watch(passwordsListControllerProvider);
  return asyncState.error?.toString();
});

/// Provider для проверки наличия дополнительных данных
final hasMorePasswordsProvider = Provider<bool>((ref) {
  final asyncState = ref.watch(passwordsListControllerProvider);
  return asyncState.value?.hasMore ?? false;
});

/// Provider для общего количества паролей
final passwordsTotalCountProvider = Provider<int>((ref) {
  final asyncState = ref.watch(passwordsListControllerProvider);
  return asyncState.value?.totalCount ?? 0;
});

/// Provider для уведомления об изменениях паролей
/// Используется для обновления списка после создания/изменения пароля
final passwordChangeNotifierProvider = Provider<void Function()>((ref) {
  return () {
    ref.read(passwordsListControllerProvider.notifier).notifyPasswordChanged();
  };
});
