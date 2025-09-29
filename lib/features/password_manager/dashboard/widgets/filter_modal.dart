import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/common/text_field.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/filters/category_filter/category_filter_widget.dart';
import 'package:hoplixi/features/password_manager/filters/tag_filter/tag_filter_widget.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/services_providers.dart' as services;

// Модели и провайдеры
import '../models/entety_type.dart';
import '../providers/filter_providers/entety_type_provider.dart';
import '../providers/filter_providers/filter_providers.dart';

// Секции фильтров
import 'filter_sections/filter_sections.dart';

/// Модальное окно фильтра, которое работает с провайдерами
/// и автоматически адаптируется под выбранный тип сущности
class FilterModal extends ConsumerStatefulWidget {
  /// Колбэк для применения фильтров
  final VoidCallback? onFilterApplied;

  const FilterModal({super.key, this.onFilterApplied});

  @override
  ConsumerState<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends ConsumerState<FilterModal> {
  late TextEditingController _searchController;

  // Состояние для выбранных категорий и тегов
  List<store.Category> _selectedCategories = [];
  List<store.Tag> _selectedTags = [];

  // Контроллеры для хранения начальных значений полей
  Map<String, dynamic> _initialValues = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    logDebug('FilterModal: Инициализация модального окна фильтра');
  }

  void _initializeControllers() {
    // Получаем текущий поисковый запрос из базового фильтра
    final baseFilter = ref.read(baseFilterProvider);
    _searchController = TextEditingController(text: baseFilter.query);

    // Сохраняем начальные значения для возможного сброса
    _saveInitialValues();

    // Загружаем выбранные категории и теги
    _loadSelectedCategoriesAndTags();
  }

  void _saveInitialValues() {
    final currentEntityType = ref.read(currentEntityTypeProvider);
    final baseFilter = ref.read(baseFilterProvider);

    _initialValues = {
      'searchQuery': baseFilter.query,
      'categoryIds': List<String>.from(baseFilter.categoryIds),
      'tagIds': List<String>.from(baseFilter.tagIds),
      'isFavorite': baseFilter.isFavorite,
      'isArchived': baseFilter.isArchived,
      'hasNotes': baseFilter.hasNotes,
      'createdAfter': baseFilter.createdAfter,
      'createdBefore': baseFilter.createdBefore,
      'modifiedAfter': baseFilter.modifiedAfter,
      'modifiedBefore': baseFilter.modifiedBefore,
      'lastAccessedAfter': baseFilter.lastAccessedAfter,
      'lastAccessedBefore': baseFilter.lastAccessedBefore,
      'sortDirection': baseFilter.sortDirection,
      'limit': baseFilter.limit,
      'offset': baseFilter.offset,
    };

    // Сохраняем специфичные для типа значения
    switch (currentEntityType) {
      case EntityType.password:
        final passwordFilter = ref.read(passwordFilterProvider);
        _initialValues.addAll({
          'name': passwordFilter.name,
          'url': passwordFilter.url,
          'username': passwordFilter.username,
          'hasUrl': passwordFilter.hasUrl,
          'hasUsername': passwordFilter.hasUsername,
          'hasTotp': passwordFilter.hasTotp,
          'isCompromised': passwordFilter.isCompromised,
          'isExpired': passwordFilter.isExpired,
          'isFrequent': passwordFilter.isFrequent,
          'passwordSortField': passwordFilter.sortField,
        });
        break;
      case EntityType.note:
        final notesFilter = ref.read(notesFilterProvider);
        _initialValues.addAll({
          'title': notesFilter.title,
          'content': notesFilter.content,
          'isPinned': notesFilter.isPined,
          'hasContent': notesFilter.hasContent,
          'minContentLength': notesFilter.minContentLength,
          'maxContentLength': notesFilter.maxContentLength,
          'hasAttachments': notesFilter.hasAttachments,
          'notesSortField': notesFilter.sortField,
        });
        break;
      case EntityType.otp:
        final otpFilter = ref.read(otpFilterProvider);
        _initialValues.addAll({
          'issuer': otpFilter.issuer,
          'accountName': otpFilter.accountName,
          'otpSortField': otpFilter.sortField,
        });
        break;
    }
  }

  /// Асинхронная загрузка выбранных категорий и тегов
  Future<void> _loadSelectedCategoriesAndTags() async {
    try {
      final baseFilter = ref.read(baseFilterProvider);
      final categoryIds = baseFilter.categoryIds;
      final tagIds = baseFilter.tagIds;

      // Загружаем категории по ID
      if (categoryIds.isNotEmpty) {
        final categoriesService = ref.read(services.categoriesServiceProvider);
        final loadedCategories = <store.Category>[];

        for (final id in categoryIds) {
          final category = await categoriesService.getCategory(id);
          if (category != null) {
            loadedCategories.add(category);
          }
        }

        if (loadedCategories.isNotEmpty) {
          setState(() {
            _selectedCategories = loadedCategories;
          });
          logDebug(
            'FilterModal: Загружено категорий: ${_selectedCategories.length}',
          );
        }
      }

      // Загружаем теги по ID
      if (tagIds.isNotEmpty) {
        final tagsService = ref.read(services.tagsServiceProvider);
        final loadedTags = <store.Tag>[];

        for (final id in tagIds) {
          final tag = await tagsService.getTag(id);
          if (tag != null) {
            loadedTags.add(tag);
          }
        }

        if (loadedTags.isNotEmpty) {
          setState(() {
            _selectedTags = loadedTags;
          });
          logDebug('FilterModal: Загружено тегов: ${_selectedTags.length}');
        }
      }
    } catch (e) {
      ToastHelper.error(
        title: 'Ошибка загрузки',
        description: 'Не удалось загрузить выбранные категории и теги',
      );
      logError('Ошибка при загрузке выбранных категорий и тегов', error: e);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentEntityType = ref.watch(currentEntityTypeProvider);

    return Dialog(
      insetPadding: const EdgeInsets.all(8),
      // backgroundColor: Theme.of(context).colorScheme.surface,
      child: Container(
        width: MediaQuery.of(context).size.width * 1,
        height: MediaQuery.of(context).size.height * 1,
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 900),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Фильтры для ${currentEntityType.label}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Содержимое
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Поиск
                    _buildSearchSection(),
                    const SizedBox(height: 24),

                    // Категории
                    _buildCategoriesSection(),
                    const SizedBox(height: 24),

                    // Теги
                    _buildTagsSection(),
                    const SizedBox(height: 24),

                    // Базовые фильтры
                    _buildBaseFiltersSection(currentEntityType),
                    const SizedBox(height: 24),

                    // Специфические фильтры
                    _buildSpecificFiltersSection(currentEntityType),
                  ],
                ),
              ),
            ),

            // Кнопки действий
            const SizedBox(height: 18),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return _buildSection(
      title: 'Поиск',
      child: PrimaryTextField(
        controller: _searchController,
        label: 'Поисковый запрос',
        hintText: 'Введите текст для поиска...',
        prefixIcon: const Icon(Icons.search),
        onChanged: (value) {
          ref.read(baseFilterProvider.notifier).updateQuery(value);
        },
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final currentEntityType = ref.watch(currentEntityTypeProvider);

    return _buildSection(
      title: 'Категории',
      child: CategoryFilterWidget(
        categoryType: _getCategoryType(currentEntityType),
        selectedCategories: _selectedCategories,
        onSelect: (category) {
          setState(() {
            if (!_selectedCategories.contains(category)) {
              _selectedCategories.add(category);
            }
          });
          _updateFilterCategories();
        },
        onRemove: (category) {
          setState(() {
            _selectedCategories.remove(category);
          });
          _updateFilterCategories();
        },
        onClearAll: () {
          setState(() {
            _selectedCategories.clear();
          });
          _updateFilterCategories();
        },
      ),
    );
  }

  Widget _buildTagsSection() {
    final currentEntityType = ref.watch(currentEntityTypeProvider);

    return _buildSection(
      title: 'Теги',
      child: TagFilterWidget(
        tagType: _getTagType(currentEntityType),
        selectedTags: _selectedTags,
        onTagSelect: (tag) {
          setState(() {
            if (!_selectedTags.contains(tag)) {
              _selectedTags.add(tag);
            }
          });
          _updateFilterTags();
        },
        onTagRemove: (tag) {
          setState(() {
            _selectedTags.remove(tag);
          });
          _updateFilterTags();
        },
        onClearAll: () {
          setState(() {
            _selectedTags.clear();
          });
          _updateFilterTags();
        },
      ),
    );
  }

  Widget _buildBaseFiltersSection(EntityType entityType) {
    final baseFilter = ref.watch(baseFilterProvider);

    return _buildSection(
      title: 'Общие фильтры',
      child: BaseFilterSection(
        filter: baseFilter,
        entityTypeName: "",
        onFilterChanged: (newFilter) {
          ref.read(baseFilterProvider.notifier).applyFilter(newFilter);
        },
      ),
    );
  }

  Widget _buildSpecificFiltersSection(EntityType entityType) {
    switch (entityType) {
      case EntityType.password:
        final passwordFilter = ref.watch(passwordFilterProvider);
        return _buildSection(
          title: 'Фильтры паролей',
          child: PasswordFilterSection(
            filter: passwordFilter,
            onFilterChanged: (newFilter) {
              ref.read(passwordFilterProvider.notifier).applyFilter(newFilter);
            },
          ),
        );

      case EntityType.note:
        final notesFilter = ref.watch(notesFilterProvider);
        return _buildSection(
          title: 'Фильтры заметок',
          child: NotesFilterSection(
            filter: notesFilter,
            onFilterChanged: (newFilter) {
              ref.read(notesFilterProvider.notifier).applyFilter(newFilter);
            },
          ),
        );

      case EntityType.otp:
        final otpFilter = ref.watch(otpFilterProvider);
        return _buildSection(
          title: 'Фильтры OTP',
          child: OtpFilterSection(
            filter: otpFilter,
            onFilterChanged: (newFilter) {
              ref.read(otpFilterProvider.notifier).applyFilter(newFilter);
            },
          ),
        );
    }
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   title,
        //   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        // ),
        // const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: SmoothButton(
            onPressed: _resetFilters,
            label: 'Сбросить',
            type: SmoothButtonType.text,
            isFullWidth: true,
          ),
        ),
        Expanded(
          child: SmoothButton(
            label: 'Применить',
            onPressed: () => _applyFilters(context),
            type: SmoothButtonType.filled,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }

  // Методы для работы с категориями и тегами
  CategoryType _getCategoryType(EntityType entityType) {
    switch (entityType) {
      case EntityType.password:
        return CategoryType.password;
      case EntityType.note:
        return CategoryType.notes;
      case EntityType.otp:
        return CategoryType.totp;
    }
  }

  TagType _getTagType(EntityType entityType) {
    switch (entityType) {
      case EntityType.password:
        return TagType.password;
      case EntityType.note:
        return TagType.notes;
      case EntityType.otp:
        return TagType.totp;
    }
  }

  void _updateFilterCategories() {
    final categoryIds = _selectedCategories.map((c) => c.id).toList();
    ref.read(baseFilterProvider.notifier).updateCategoryIds(categoryIds);
    logDebug('FilterModal: Обновлены категории фильтра: ${categoryIds.length}');
  }

  void _updateFilterTags() {
    final tagIds = _selectedTags.map((t) => t.id).toList();
    ref.read(baseFilterProvider.notifier).updateTagIds(tagIds);
    logDebug('FilterModal: Обновлены теги фильтра: ${tagIds.length}');
  }

  void _resetFilters() {
    logDebug('FilterModal: Сброс всех фильтров');

    try {
      // Сбрасываем базовый фильтр
      ref.read(baseFilterProvider.notifier).reset();

      // Сбрасываем специфические фильтры в зависимости от типа
      final currentEntityType = ref.read(currentEntityTypeProvider);
      switch (currentEntityType) {
        case EntityType.password:
          ref.read(passwordFilterProvider.notifier).reset();
          break;
        case EntityType.note:
          ref.read(notesFilterProvider.notifier).reset();
          break;
        case EntityType.otp:
          ref.read(otpFilterProvider.notifier).reset();
          break;
      }

      // Очищаем локальное состояние
      setState(() {
        _selectedCategories.clear();
        _selectedTags.clear();
        _searchController.clear();
      });

      ToastHelper.success(
        title: 'Фильтры сброшены',
        description: 'Все фильтры были сброшены к значениям по умолчанию',
      );
    } catch (e) {
      logError('Ошибка при сбросе фильтров', error: e);
      ToastHelper.error(
        title: 'Ошибка',
        description: 'Не удалось сбросить фильтры',
      );
    }
  }

  void _applyFilters(BuildContext context) {
    logDebug('FilterModal: Применение фильтров');

    try {
      // Синхронизируем выбранные категории и теги с провайдерами
      _updateFilterCategories();
      _updateFilterTags();

      // Уведомляем о применении фильтров
      widget.onFilterApplied?.call();

      ToastHelper.success(
        title: 'Фильтры применены',
        description: 'Фильтры успешно применены к списку',
      );

      // Закрываем модальное окно
      context.pop();
    } catch (e) {
      logError('Ошибка при применении фильтров', error: e);
      ToastHelper.error(
        title: 'Ошибка',
        description: 'Не удалось применить фильтры',
      );
    }
  }
}
