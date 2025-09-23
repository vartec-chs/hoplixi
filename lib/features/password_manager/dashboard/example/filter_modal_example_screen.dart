import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

// Импорты для нашего FilterModal
import '../models/entety_type.dart';
import '../providers/entety_type_provider.dart';
import '../providers/filter_providers.dart';
import '../providers/filter_tabs_provider.dart';
import '../widgets/filter_modal.dart';
import '../widgets/entity_type_dropdown.dart';
import '../widgets/filter_tabs.dart';

/// Демонстрационный экран для FilterModal
/// Показывает как использовать FilterModal с провайдерами типа сущности и фильтров
class FilterModalExampleScreen extends ConsumerWidget {
  const FilterModalExampleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentEntityType = ref.watch(currentEntityTypeProvider);
    final baseFilter = ref.watch(baseFilterProvider);
    final currentTab = ref.watch(filterTabsControllerProvider);

    // Слушаем изменения типа сущности для синхронизации вкладок
    ref.listen(currentEntityTypeProvider, (previous, next) {
      if (previous != next) {
        ref.read(filterTabsControllerProvider.notifier).syncWithEntityType();
        logInfo('Синхронизация FilterTabs с типом сущности: ${next.label}');
      }
    });

    // Получаем соответствующий специфический фильтр в зависимости от типа
    Widget specificFilterInfo;
    switch (currentEntityType) {
      case EntityType.password:
        final passwordFilter = ref.watch(passwordFilterProvider);
        specificFilterInfo = _buildPasswordFilterInfo(passwordFilter);
        break;
      case EntityType.note:
        final notesFilter = ref.watch(notesFilterProvider);
        specificFilterInfo = _buildNotesFilterInfo(notesFilter);
        break;
      case EntityType.otp:
        final otpFilter = ref.watch(otpFilterProvider);
        specificFilterInfo = _buildOtpFilterInfo(otpFilter);
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Демонстрация FilterModal'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Селектор типа сущности
            EntityTypeDropdown(
              onEntityTypeChanged: (entityType) {
                logInfo('Тип сущности изменен: ${entityType.label}');
              },
            ),
            const SizedBox(height: 16),

            // Компонент вкладок фильтров
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Вкладки фильтров',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    FilterTabs(
                      onTabChanged: (tab) {
                        logInfo('Изменена вкладка фильтра: ${tab.label}');
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Активная вкладка: ${currentTab.label}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Кнопка открытия фильтра
            Center(
              child: SmoothButton(
                label: 'Открыть фильтр для ${currentEntityType.label}',
                onPressed: () => _openFilterModal(context),
                type: SmoothButtonType.filled,
                size: SmoothButtonSize.large,
                icon: const Icon(Icons.filter_list),
              ),
            ),
            const SizedBox(height: 32),

            // Информация о текущих фильтрах
            _buildCurrentFiltersSection(
              context,
              ref,
              baseFilter,
              specificFilterInfo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentFiltersSection(
    BuildContext context,
    WidgetRef ref,
    dynamic baseFilter,
    Widget specificFilterInfo,
  ) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Текущие фильтры',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Базовые фильтры
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Базовые фильтры',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildBaseFilterInfo(baseFilter),
                    const Divider(),
                    _buildFilterTabInfo(context, ref),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Специфические фильтры
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Специфические фильтры',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    specificFilterInfo,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBaseFilterInfo(dynamic baseFilter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          'Поисковый запрос',
          baseFilter.query?.isNotEmpty == true ? baseFilter.query : 'Не указан',
        ),
        _buildInfoRow('Категории', '${baseFilter.categoryIds.length}'),
        _buildInfoRow('Теги', '${baseFilter.tagIds.length}'),
        _buildInfoRow('Избранное', _boolToString(baseFilter.isFavorite)),
        _buildInfoRow('Архивное', _boolToString(baseFilter.isArchived)),
        _buildInfoRow('Есть заметки', _boolToString(baseFilter.hasNotes)),
        _buildInfoRow(
          'Направление сортировки',
          baseFilter.sortDirection.toString(),
        ),
        if (baseFilter.limit != null)
          _buildInfoRow('Лимит', baseFilter.limit.toString()),
        if (baseFilter.offset != null)
          _buildInfoRow('Смещение', baseFilter.offset.toString()),
      ],
    );
  }

  Widget _buildFilterTabInfo(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(filterTabsControllerProvider);
    final availableTabs = ref.watch(availableFilterTabsProvider);
    final currentEntityType = ref.watch(currentEntityTypeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Информация о вкладках',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildInfoRow('Текущая вкладка', currentTab.label),
        _buildInfoRow('Тип сущности', currentEntityType.label),
        _buildInfoRow('Доступные вкладки', '${availableTabs.length}'),
        _buildInfoRow(
          'Список доступных',
          availableTabs.map((tab) => tab.label).join(', '),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              currentTab.icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Активный фильтр: ${currentTab.label}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordFilterInfo(dynamic passwordFilter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Название', passwordFilter.name ?? 'Не указано'),
        _buildInfoRow('URL', passwordFilter.url ?? 'Не указан'),
        _buildInfoRow(
          'Имя пользователя',
          passwordFilter.username ?? 'Не указано',
        ),
        _buildInfoRow('Есть URL', _boolToString(passwordFilter.hasUrl)),
        _buildInfoRow(
          'Есть имя пользователя',
          _boolToString(passwordFilter.hasUsername),
        ),
        _buildInfoRow('Есть TOTP', _boolToString(passwordFilter.hasTotp)),
        _buildInfoRow(
          'Скомпрометированный',
          _boolToString(passwordFilter.isCompromised),
        ),
        _buildInfoRow('Истекший', _boolToString(passwordFilter.isExpired)),
        _buildInfoRow(
          'Часто используемый',
          _boolToString(passwordFilter.isFrequent),
        ),
        if (passwordFilter.sortField != null)
          _buildInfoRow('Поле сортировки', passwordFilter.sortField.toString()),
      ],
    );
  }

  Widget _buildNotesFilterInfo(dynamic notesFilter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Заголовок', notesFilter.title ?? 'Не указан'),
        _buildInfoRow('Содержимое', notesFilter.content ?? 'Не указано'),
        _buildInfoRow('Закрепленная', _boolToString(notesFilter.isPined)),
        _buildInfoRow('Есть содержимое', _boolToString(notesFilter.hasContent)),
        _buildInfoRow(
          'Есть вложения',
          _boolToString(notesFilter.hasAttachments),
        ),
        if (notesFilter.minContentLength != null)
          _buildInfoRow(
            'Мин. длина содержимого',
            notesFilter.minContentLength.toString(),
          ),
        if (notesFilter.maxContentLength != null)
          _buildInfoRow(
            'Макс. длина содержимого',
            notesFilter.maxContentLength.toString(),
          ),
        if (notesFilter.sortField != null)
          _buildInfoRow('Поле сортировки', notesFilter.sortField.toString()),
      ],
    );
  }

  Widget _buildOtpFilterInfo(dynamic otpFilter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (otpFilter.type != null)
          _buildInfoRow('Тип OTP', otpFilter.type.toString()),
        _buildInfoRow('Издатель', otpFilter.issuer ?? 'Не указан'),
        _buildInfoRow('Имя аккаунта', otpFilter.accountName ?? 'Не указано'),
        if (otpFilter.algorithms != null && otpFilter.algorithms!.isNotEmpty)
          _buildInfoRow('Алгоритмы', otpFilter.algorithms!.join(', ')),
        if (otpFilter.digits != null)
          _buildInfoRow('Количество цифр', otpFilter.digits.toString()),
        if (otpFilter.period != null)
          _buildInfoRow('Период', '${otpFilter.period} сек'),
        _buildInfoRow(
          'Есть связь с паролем',
          _boolToString(otpFilter.hasPasswordLink),
        ),
        if (otpFilter.sortField != null)
          _buildInfoRow('Поле сортировки', otpFilter.sortField.toString()),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  String _boolToString(bool? value) {
    if (value == null) return 'Не задано';
    return value ? 'Да' : 'Нет';
  }

  void _openFilterModal(BuildContext context) {
    logInfo('Открытие FilterModal');

    showDialog(
      context: context,
      builder: (context) => FilterModal(
        onFilterApplied: () {
          logInfo('Фильтры применены в FilterModal');
        },
      ),
    );
  }
}
