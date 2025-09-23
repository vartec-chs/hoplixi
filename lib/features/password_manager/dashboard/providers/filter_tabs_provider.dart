import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/filter_tab.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/entety_type_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/base_filter_provider.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

/// Провайдер для управления вкладками фильтров
final filterTabsControllerProvider =
    NotifierProvider<FilterTabsController, FilterTab>(
      () => FilterTabsController(),
    );

/// Провайдер для получения доступных вкладок для текущего типа сущности
final availableFilterTabsProvider = Provider<List<FilterTab>>((ref) {
  final entityType = ref.watch(currentEntityTypeProvider);
  return FilterTab.getAvailableTabsForEntity(entityType);
});

/// Контроллер для управления состоянием вкладок фильтров
class FilterTabsController extends Notifier<FilterTab> {
  @override
  FilterTab build() {
    // Получаем текущий тип сущности и возвращаем первую доступную вкладку
    final entityType = ref.read(currentEntityTypeProvider);
    final availableTabs = FilterTab.getAvailableTabsForEntity(entityType);

    logDebug(
      'FilterTabsController: Инициализация',
      data: {
        'entityType': entityType.id,
        'defaultTab': availableTabs.first.label,
      },
    );

    return availableTabs.first;
  }

  /// Изменяет активную вкладку
  void changeTab(FilterTab tab) {
    if (state != tab) {
      logDebug(
        'FilterTabsController: Изменение вкладки',
        data: {'previousTab': state.label, 'newTab': tab.label},
      );

      state = tab;
      _applyTabFilters(tab);
    }
  }

  /// Применяет фильтры в соответствии с выбранной вкладкой
  void _applyTabFilters(FilterTab tab) {
    final baseFilterNotifier = ref.read(baseFilterProvider.notifier);

    switch (tab) {
      case FilterTab.all:
        // Сбрасываем фильтры избранного и архивного
        baseFilterNotifier.updateFavorite(null);
        baseFilterNotifier.updateArchived(null);
        break;

      case FilterTab.favorites:
        // Показываем только избранные, исключаем архивные
        baseFilterNotifier.updateFavorite(true);
        baseFilterNotifier.updateArchived(false);
        break;

      case FilterTab.frequent:
        // Для частых не устанавливаем базовые фильтры,
        // логика обрабатывается в соответствующих провайдерах
        baseFilterNotifier.updateFavorite(null);
        baseFilterNotifier.updateArchived(false);
        break;

      case FilterTab.archived:
        // Показываем только архивные
        baseFilterNotifier.updateArchived(true);
        baseFilterNotifier.updateFavorite(null);
        break;
    }

    logDebug(
      'FilterTabsController: Применены фильтры для вкладки',
      data: {
        'tab': tab.label,
        'isFavorite': baseFilterNotifier.state.isFavorite,
        'isArchived': baseFilterNotifier.state.isArchived,
      },
    );
  }

  /// Получает текущую вкладку для типа сущности
  FilterTab getTabForEntityType() {
    final entityType = ref.read(currentEntityTypeProvider);
    final availableTabs = FilterTab.getAvailableTabsForEntity(entityType);

    // Если текущая вкладка доступна для типа сущности, возвращаем её
    if (availableTabs.contains(state)) {
      return state;
    }

    // Иначе возвращаем первую доступную
    return availableTabs.first;
  }

  /// Синхронизирует вкладку с изменением типа сущности
  void syncWithEntityType() {
    final currentTab = getTabForEntityType();
    if (currentTab != state) {
      logDebug(
        'FilterTabsController: Синхронизация с типом сущности',
        data: {
          'entityType': ref.read(currentEntityTypeProvider).id,
          'newTab': currentTab.label,
        },
      );
      changeTab(currentTab);
    }
  }

  /// Проверяет, доступна ли вкладка для текущего типа сущности
  bool isTabAvailable(FilterTab tab) {
    final availableTabs = ref.read(availableFilterTabsProvider);
    return availableTabs.contains(tab);
  }
}
