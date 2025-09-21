import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/universal_filter/universal_filter_barrel.dart';
import 'package:hoplixi/hoplixi_store/models/filter/password_filter.dart';
import 'package:hoplixi/hoplixi_store/models/filter/base_filter.dart';
import 'package:hoplixi/hoplixi_store/models/filter/notes_filter.dart';
import 'package:hoplixi/hoplixi_store/models/filter/otp_filter.dart';
import 'package:hoplixi/hoplixi_store/models/filter/attachments_filter.dart';
import 'package:hoplixi/features/password_manager/filters/category_filter/category_filter.dart';
import 'package:hoplixi/features/password_manager/filters/tag_filter/tag_filter.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/services_providers.dart' as services;

// Секции
import 'sections/password_filter_section.dart';
import 'sections/notes_filter_section.dart';
import 'sections/otp_filter_section.dart';
import 'sections/attachments_filter_section.dart';

// Миксины
import 'mixins/filter_helper_mixin.dart';

/// Основное модальное окно универсального фильтра
class UniversalFilterModal extends ConsumerStatefulWidget {
  final UniversalFilter initialFilter;
  final Function(UniversalFilter) onFilterApplied;

  const UniversalFilterModal({
    super.key,
    required this.initialFilter,
    required this.onFilterApplied,
  });

  @override
  ConsumerState<UniversalFilterModal> createState() =>
      _UniversalFilterModalState();
}

class _UniversalFilterModalState extends ConsumerState<UniversalFilterModal>
    with FilterHelperMixin {
  late UniversalFilter _currentFilter;
  late TextEditingController _searchController;

  // Состояние для выбранных категорий и тегов
  List<store.Category> _selectedCategories = [];
  List<store.Tag> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    _searchController = TextEditingController(text: _currentFilter.searchQuery);
    _initializeSelectedItems();
  }

  void _initializeSelectedItems() {
    // Загружаем выбранные категории и теги на основе ID из _currentFilter
    _loadSelectedCategoriesAndTags();
  }

  /// Асинхронная загрузка выбранных категорий и тегов
  Future<void> _loadSelectedCategoriesAndTags() async {
    try {
      final categoryIds = _currentFilter.categoryIds;
      final tagIds = _currentFilter.tagIds;

      // Загружаем категории по ID
      if (categoryIds.isNotEmpty) {
        final categoriesService = ref.read(services.categoriesServiceProvider);
        final categories = <store.Category>[];

        for (final categoryId in categoryIds) {
          final category = await categoriesService.getCategory(categoryId);
          if (category != null) {
            categories.add(category);
          }
        }

        if (mounted) {
          setState(() {
            _selectedCategories = categories;
          });
        }
      }

      // Загружаем теги по ID
      if (tagIds.isNotEmpty) {
        final tagsService = ref.read(services.tagsServiceProvider);
        final tags = <store.Tag>[];

        for (final tagId in tagIds) {
          final tag = await tagsService.getTag(tagId);
          if (tag != null) {
            tags.add(tag);
          }
        }

        if (mounted) {
          setState(() {
            _selectedTags = tags;
          });
        }
      }
    } catch (e) {
      // В случае ошибки логируем её, но не блокируем работу UI
      logError(
        'Ошибка загрузки выбранных категорий и тегов',
        error: e,
        tag: 'UniversalFilterModal',
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Text(
                  getModalTitle(_currentFilter.entityType),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            // Содержимое с прокруткой
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                dragStartBehavior: DragStartBehavior.start,
                primary: true,

                scrollDirection: Axis.vertical,
                child: Column(
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Поиск
                    _buildSearchSection(),

                    // Категории
                    _buildCategoriesSection(),

                    // Теги
                    _buildTagsSection(),

                    // Специфичные фильтры для типа записи
                    _buildSpecificFiltersSection(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Кнопки действий
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Поиск',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: getSearchHint(_currentFilter.entityType),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _updateQuery('');
                    },
                    icon: const Icon(Icons.clear),
                  )
                : null,
          ),
          onChanged: _updateQuery,
        ),
      ],
    );
  }

  // Секция категорий
  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Категории',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        CategoryFilterWidget(
          categoryType: _getCategoryType(_currentFilter.entityType),
          selectedCategories: _selectedCategories,
          onSelect: (category) {
            setState(() {
              if (!_selectedCategories.any((c) => c.id == category.id)) {
                _selectedCategories.add(category);
                _updateFilterCategories();
              }
            });
          },
          onRemove: (category) {
            setState(() {
              _selectedCategories.removeWhere((c) => c.id == category.id);
              _updateFilterCategories();
            });
          },
          onClearAll: () {
            setState(() {
              _selectedCategories.clear();
              _updateFilterCategories();
            });
          },
          searchPlaceholder: 'Поиск категорий...',
          modalTitle: 'Выбор категорий',
          height: 60,
        ),
      ],
    );
  }

  // Секция тегов
  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Теги',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TagFilterWidget(
          tagType: _getTagType(_currentFilter.entityType),
          selectedTags: _selectedTags,
          onTagSelect: (tag) {
            setState(() {
              if (!_selectedTags.any((t) => t.id == tag.id)) {
                _selectedTags.add(tag);
                _updateFilterTags();
              }
            });
          },
          onTagRemove: (tag) {
            setState(() {
              _selectedTags.removeWhere((t) => t.id == tag.id);
              _updateFilterTags();
            });
          },
          onClearAll: () {
            setState(() {
              _selectedTags.clear();
              _updateFilterTags();
            });
          },
          searchPlaceholder: 'Поиск тегов...',
          modalTitle: 'Выбор тегов',
          height: 60,
        ),
      ],
    );
  }

  Widget _buildSpecificFiltersSection() {
    switch (_currentFilter.entityType) {
      case UniversalEntityType.password:
        return _buildSection(
          title: 'Фильтры для паролей',
          child: PasswordFilterSection(
            filter:
                _currentFilter.passwordFilter ??
                const PasswordFilter(base: BaseFilter()),
            onFilterChanged: (passwordFilter) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  passwordFilter: passwordFilter,
                );
              });
            },
          ),
        );

      case UniversalEntityType.note:
        return _buildSection(
          title: 'Фильтры для заметок',
          child: NotesFilterSection(
            filter:
                _currentFilter.notesFilter ??
                const NotesFilter(base: BaseFilter()),
            onFilterChanged: (notesFilter) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  notesFilter: notesFilter,
                );
              });
            },
          ),
        );

      case UniversalEntityType.otp:
        return _buildSection(
          title: 'Фильтры для OTP',
          child: OtpFilterSection(
            filter:
                _currentFilter.otpFilter ?? const OtpFilter(base: BaseFilter()),
            onFilterChanged: (otpFilter) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(otpFilter: otpFilter);
              });
            },
          ),
        );

      case UniversalEntityType.attachment:
        return _buildSection(
          title: 'Фильтры для вложений',
          child: AttachmentsFilterSection(
            filter:
                _currentFilter.attachmentsFilter ??
                const AttachmentsFilter(base: BaseFilter()),
            onFilterChanged: (attachmentsFilter) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  attachmentsFilter: attachmentsFilter,
                );
              });
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
        // const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: SmoothButton(
            label: 'Сбросить',
            onPressed: _resetFilters,
            size: SmoothButtonSize.medium,
            type: SmoothButtonType.tonal,
          ),
        ),

        // Expanded(
        //   child: SmoothButton(
        //     label: 'Отмена',
        //     onPressed: () {
        //       context.pop();
        //     },
        //     type: SmoothButtonType.text,
        //   ),
        // ),
        Expanded(
          flex: !isMobile ? 2 : 1,
          child: SmoothButton(
            onPressed: () => _applyFilters(context),
            label: 'Применить',
            type: SmoothButtonType.filled,
            size: SmoothButtonSize.medium,
          ),
        ),
      ],
    );
  }

  // Методы для работы с категориями и тегами
  CategoryType _getCategoryType(UniversalEntityType entityType) {
    switch (entityType) {
      case UniversalEntityType.password:
        return CategoryType.password;
      case UniversalEntityType.note:
        return CategoryType.notes;
      case UniversalEntityType.otp:
        return CategoryType.totp;
      case UniversalEntityType.attachment:
        return CategoryType.mixed;
    }
  }

  TagType _getTagType(UniversalEntityType entityType) {
    switch (entityType) {
      case UniversalEntityType.password:
        return TagType.password;
      case UniversalEntityType.note:
        return TagType.notes;
      case UniversalEntityType.otp:
        return TagType.totp;
      case UniversalEntityType.attachment:
        return TagType.mixed;
    }
  }

  void _updateFilterCategories() {
    final categoryIds = _selectedCategories.map((c) => c.id).toList();
    setState(() {
      _currentFilter = _currentFilter.updateCategories(categoryIds);
    });
  }

  void _updateFilterTags() {
    final tagIds = _selectedTags.map((t) => t.id).toList();
    setState(() {
      _currentFilter = _currentFilter.updateTags(tagIds);
    });
  }

  void _updateQuery(String query) {
    setState(() {
      _currentFilter = _currentFilter.updateSearchQuery(query);
    });
  }

  void _resetFilters() {
    setState(() {
      _currentFilter = UniversalFilter.empty(_currentFilter.entityType);
      _searchController.clear();
      _selectedCategories.clear();
      _selectedTags.clear();
    });
  }

  void _applyFilters(BuildContext context) {
    // Синхронизируем выбранные категории и теги с фильтром перед применением
    _updateFilterCategories();
    _updateFilterTags();

    widget.onFilterApplied(_currentFilter);
    context.pop();
  }
}
