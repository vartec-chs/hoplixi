import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/universal_filter/models/password_list_state.dart';
import 'package:hoplixi/hoplixi_store/dao/filters_dao/password_filter_dao.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/models/filter/password_filter.dart';
import 'package:hoplixi/hoplixi_store/models/filter/base_filter.dart';
import 'package:hoplixi/hoplixi_store/services_providers.dart';

/// Контроллер для управления списком паролей с пагинацией
class PasswordListController extends Notifier<PasswordListState> {
  late final PasswordFilterDao _passwordFilterDao;

  @override
  PasswordListState build() {
    // Получаем DAO через ref
    _passwordFilterDao = ref.read(passwordListFilterDaoProvider);

    // Создаем начальный фильтр
    final initialFilter = PasswordFilter(
      base: BaseFilter(
        query: '',
        categoryIds: [],
        tagIds: [],
        isFavorite: null,
        isArchived: false,
        sortDirection: SortDirection.desc,
        limit: 20,
        offset: 0,
      ),
      hasUrl: null,
      hasUsername: null,
      hasTotp: null,
      isCompromised: null,
      isExpired: null,
      isFrequent: null,
      sortField: null,
    );

    return PasswordListState(filter: initialFilter);
  }

  /// Загрузка первой страницы паролей
  Future<void> loadPasswords() async {
    try {
      // Устанавливаем состояние загрузки
      state = state.copyWith(isLoading: true, error: null, currentPage: 0);

      // Получаем пароли с текущим фильтром
      final passwords = await _passwordFilterDao.getFilteredPasswords(
        state.currentFilter,
      );

      // Подсчитываем общее количество
      final totalCount = await _passwordFilterDao.countFilteredPasswords(
        state.filter.copyWith(
          base: state.filter.base.copyWith(limit: null, offset: null),
        ),
      );

      // Обновляем состояние
      state = state.copyWith(
        passwords: passwords,
        isLoading: false,
        hasMore: passwords.length >= state.pageSize,
        totalCount: totalCount,
        currentPage: 0,
      );

      logDebug(
        'Загружена первая страница паролей: ${passwords.length} из $totalCount',
      );
    } catch (e, stackTrace) {
      logError('Ошибка загрузки паролей', error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка загрузки паролей: $e',
      );
    }
  }

  /// Загрузка следующей страницы паролей
  Future<void> loadMorePasswords() async {
    if (state.isLoadingMore || !state.hasMore) return;

    try {
      // Устанавливаем состояние загрузки следующей страницы
      state = state.copyWith(isLoadingMore: true, error: null);

      // Получаем пароли для следующей страницы
      final nextPagePasswords = await _passwordFilterDao.getFilteredPasswords(
        state.nextPageFilter,
      );

      // Обновляем состояние
      state = state.copyWith(
        passwords: [...state.passwords, ...nextPagePasswords],
        isLoadingMore: false,
        hasMore: nextPagePasswords.length >= state.pageSize,
        currentPage: state.currentPage + 1,
      );

      logDebug(
        'Загружена страница ${state.currentPage}: ${nextPagePasswords.length} паролей',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка загрузки следующей страницы',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Ошибка загрузки следующей страницы: $e',
      );
    }
  }

  /// Применение нового фильтра
  Future<void> applyFilter(PasswordFilter newFilter) async {
    logDebug('Применяется новый фильтр');

    state = state.copyWith(
      filter: newFilter,
      passwords: [],
      currentPage: 0,
      hasMore: true,
    );

    await loadPasswords();
  }

  /// Очистка фильтров
  Future<void> clearFilters() async {
    final clearedFilter = state.filter.copyWith(
      base: state.filter.base.copyWith(
        query: '',
        categoryIds: [],
        tagIds: [],
        isFavorite: null,
      ),
      hasUrl: null,
      hasUsername: null,
      hasTotp: null,
      isCompromised: null,
      isExpired: null,
      isFrequent: null,
    );

    await applyFilter(clearedFilter);
  }

  /// Обновление поискового запроса
  Future<void> updateSearch(String searchTerm) async {
    final updatedFilter = state.filter.copyWith(
      base: state.filter.base.copyWith(query: searchTerm),
    );

    await applyFilter(updatedFilter);
  }

  /// Переключение избранного
  Future<void> toggleFavoriteFilter() async {
    final currentFavorite = state.filter.base.isFavorite;
    bool? newFavorite;

    if (currentFavorite == null) {
      newFavorite = true;
    } else if (currentFavorite == true) {
      newFavorite = false;
    } else {
      newFavorite = null;
    }

    final updatedFilter = state.filter.copyWith(
      base: state.filter.base.copyWith(isFavorite: newFavorite),
    );

    await applyFilter(updatedFilter);
  }

  /// Обновление сортировки
  Future<void> updateSort(SortDirection direction) async {
    final updatedFilter = state.filter.copyWith(
      base: state.filter.base.copyWith(sortDirection: direction),
    );

    await applyFilter(updatedFilter);
  }

  /// Обновление категорий
  Future<void> updateCategories(List<String> categoryIds) async {
    final updatedFilter = state.filter.copyWith(
      base: state.filter.base.copyWith(categoryIds: categoryIds),
    );

    await applyFilter(updatedFilter);
  }

  /// Обновление тегов
  Future<void> updateTags(List<String> tagIds) async {
    final updatedFilter = state.filter.copyWith(
      base: state.filter.base.copyWith(tagIds: tagIds),
    );

    await applyFilter(updatedFilter);
  }

  /// Обновление пароля в списке
  void updatePassword(CardPasswordDto updatedPassword) {
    final updatedPasswords = state.passwords.map((password) {
      if (password.id == updatedPassword.id) {
        return updatedPassword;
      }
      return password;
    }).toList();

    state = state.copyWith(passwords: updatedPasswords);
  }

  /// Удаление пароля из списка
  void removePassword(String passwordId) {
    final updatedPasswords = state.passwords
        .where((password) => password.id != passwordId)
        .toList();

    state = state.copyWith(
      passwords: updatedPasswords,
      totalCount: state.totalCount - 1,
    );
  }

  /// Принудительное обновление списка
  Future<void> refresh() async {
    await loadPasswords();
  }
}

/// Провайдер для получения PasswordFilterDao
final passwordListFilterDaoProvider = Provider<PasswordFilterDao>((ref) {
  return ref.read(passwordFilterDaoProvider);
});

/// Провайдер контроллера списка паролей
final passwordListControllerProvider =
    NotifierProvider<PasswordListController, PasswordListState>(
      PasswordListController.new,
    );

/// Провайдер для автоматической загрузки паролей при изменении фильтра
final autoLoadPasswordsProvider = Provider<void>((ref) {
  final controller = ref.read(passwordListControllerProvider.notifier);

  // Загружаем пароли при первом обращении к провайдеру
  ref.onCancel(() {
    // Cleanup если необходимо
  });

  // Запускаем загрузку асинхронно
  Future.microtask(() => controller.loadPasswords());
});
