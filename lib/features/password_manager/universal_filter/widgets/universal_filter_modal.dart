import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/common/text_field.dart';
import 'package:hoplixi/features/password_manager/universal_filter/universal_filter_barrel.dart';
import 'package:hoplixi/hoplixi_store/models/filter/base_filter.dart';
import 'package:hoplixi/hoplixi_store/models/password_filter.dart';
import 'package:hoplixi/features/password_manager/filters/category_filter/category_filter_widget.dart';
import 'package:hoplixi/features/password_manager/filters/tag_filter/tag_filter_widget.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';

/// Универсальное полноэкранное модальное окно для настройки фильтров
class UniversalFilterModal extends ConsumerStatefulWidget {
  /// Начальный универсальный фильтр
  final UniversalFilter initialFilter;

  /// Callback при применении фильтра
  final void Function(UniversalFilter filter) onApply;

  /// Callback при отмене
  final VoidCallback onCancel;

  const UniversalFilterModal({
    super.key,
    required this.initialFilter,
    required this.onApply,
    required this.onCancel,
  });

  @override
  ConsumerState<UniversalFilterModal> createState() =>
      _UniversalFilterModalState();
}

class _UniversalFilterModalState extends ConsumerState<UniversalFilterModal> {
  late UniversalFilter _currentFilter;
  late TextEditingController _searchController;
  late List<String> _selectedCategoryIds;
  late List<String> _selectedTagIds;

  // Локальные состояния для категорий и тегов
  List<store.Category> _selectedCategories = [];
  List<store.Tag> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    _searchController = TextEditingController();
    _selectedCategoryIds = List.from(_currentFilter.categoryIds);
    _selectedTagIds = List.from(_currentFilter.tagIds);

    // Инициализация контроллера поиска
    _searchController.text = _currentFilter.searchQuery;

    // Инициализация локальных состояний
    _initializeLocalStates();
  }

  void _initializeLocalStates() async {
    // Загружаем реальные категории по ID
    if (_selectedCategoryIds.isNotEmpty) {
      try {
        final categoriesService = ref.read(categoriesServiceProvider);
        final categories = <store.Category>[];

        for (final id in _selectedCategoryIds) {
          final category = await categoriesService.getCategory(id);
          if (category != null) {
            categories.add(category);
          }
        }

        setState(() {
          _selectedCategories = categories;
        });
      } catch (e) {
        // Логирование ошибки
        _selectedCategories = [];
      }
    }

    // Загружаем реальные теги по ID
    if (_selectedTagIds.isNotEmpty) {
      try {
        final tagsService = ref.read(tagsServiceProvider);
        final tags = <store.Tag>[];

        for (final id in _selectedTagIds) {
          final tag = await tagsService.getTag(id);
          if (tag != null) {
            tags.add(tag);
          }
        }

        setState(() {
          _selectedTags = tags;
        });
      } catch (e) {
        // Логирование ошибки
        _selectedTags = [];
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    // Обновляем фильтр используя объекты категорий и тегов
    final updatedFilter = _currentFilter
        .updateSearchQuery(_searchController.text)
        .updateCategoriesFromObjects(_selectedCategories)
        .updateTagsFromObjects(_selectedTags);

    widget.onApply(updatedFilter);
  }

  void _resetFilter() {
    setState(() {
      _currentFilter = UniversalFilter.empty(_currentFilter.entityType);
      _selectedCategoryIds.clear();
      _selectedTagIds.clear();
      _selectedCategories.clear();
      _selectedTags.clear();
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text(_getModalTitle(_currentFilter.entityType)),
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: theme.colorScheme.surface,
          leading: IconButton(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close),
            tooltip: 'Закрыть',
          ),
          actions: [
            SmoothButton(
              onPressed: _resetFilter,
              label: 'Сбросить',
              size: SmoothButtonSize.small,
              type: SmoothButtonType.outlined,
            ),
            const SizedBox(width: 8),
            SmoothButton(
              onPressed: _applyFilter,
              label: 'Применить',
              size: SmoothButtonSize.small,
              type: SmoothButtonType.filled,
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Поиск
              _buildSection(
                title: 'Поиск',
                child: PrimaryTextField(
                  controller: _searchController,
                  hintText: _getSearchHint(_currentFilter.entityType),
                  onChanged: (value) {
                    setState(() {
                      _currentFilter = _currentFilter.updateSearchQuery(value);
                    });
                  },
                  prefixIcon: const Icon(Icons.search),
                ),
              ),

              const SizedBox(height: 24),

              // Категории - заглушка пока что
              _buildSection(
                title: 'Категории',
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Фильтрация по категориям будет добавлена в следующих версиях',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Теги - заглушка пока что
              _buildSection(
                title: 'Теги',
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Фильтрация по тегам будет добавлена в следующих версиях',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Специфичные для типа фильтры
              _buildTypeSpecificFilters(),

              const SizedBox(height: 24),

              // Общие фильтры
              _buildCommonFilters(),

              const SizedBox(height: 24),

              // Сортировка
              _buildSortingSection(),

              // Добавляем отступ в конце для удобства прокрутки
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildTypeSpecificFilters() {
    switch (_currentFilter.entityType) {
      case UniversalEntityType.password:
        return _buildPasswordSpecificFilters();
      case UniversalEntityType.note:
        return _buildNoteSpecificFilters();
      case UniversalEntityType.otp:
        return _buildOtpSpecificFilters();
      case UniversalEntityType.attachment:
        return _buildAttachmentSpecificFilters();
    }
  }

  Widget _buildPasswordSpecificFilters() {
    final theme = Theme.of(context);
    final passwordFilter =
        _currentFilter.passwordFilter ?? const PasswordFilter();

    return _buildSection(
      title: 'Фильтры для паролей',
      child: Column(
        children: [
          CheckboxListTile(
            title: const Text('Только часто используемые'),
            value: passwordFilter.isFrequent,
            tristate: true,
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  passwordFilter: passwordFilter.copyWith(isFrequent: value),
                );
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            title: const Text('Только с заметками'),
            value: passwordFilter.hasNotes,
            tristate: true,
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  passwordFilter: passwordFilter.copyWith(hasNotes: value),
                );
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSpecificFilters() {
    final theme = Theme.of(context);
    final notesFilter = _currentFilter.notesFilter;

    return _buildSection(
      title: 'Фильтры для заметок',
      child: Column(
        children: [
          CheckboxListTile(
            title: const Text('Только закрепленные'),
            value: notesFilter?.base.isPinned,
            tristate: true,
            onChanged: (value) {
              setState(() {
                final currentBase = notesFilter?.base ?? const BaseFilter();
                _currentFilter = _currentFilter.copyWith(
                  notesFilter: notesFilter?.copyWith(
                    base: currentBase.copyWith(isPinned: value),
                  ),
                );
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            title: const Text('Только с содержимым'),
            value: notesFilter?.hasContent,
            tristate: true,
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  notesFilter: notesFilter?.copyWith(hasContent: value),
                );
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpSpecificFilters() {
    final theme = Theme.of(context);
    final otpFilter = _currentFilter.otpFilter;

    return _buildSection(
      title: 'Фильтры для OTP',
      child: Column(
        children: [
          CheckboxListTile(
            title: const Text('Только связанные с паролями'),
            value: otpFilter?.hasPasswordLink,
            tristate: true,
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  otpFilter: otpFilter?.copyWith(hasPasswordLink: value),
                );
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentSpecificFilters() {
    final theme = Theme.of(context);
    final attachmentsFilter = _currentFilter.attachmentsFilter;

    return _buildSection(
      title: 'Фильтры для вложений',
      child: Column(
        children: [
          CheckboxListTile(
            title: const Text('Только с контрольной суммой'),
            value: attachmentsFilter?.hasChecksum,
            tristate: true,
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  attachmentsFilter: attachmentsFilter?.copyWith(
                    hasChecksum: value,
                  ),
                );
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildCommonFilters() {
    return _buildSection(
      title: 'Общие фильтры',
      child: Column(
        children: [
          // Фильтр по категориям
          CategoryFilterWidget(
            categoryType: _getCategoryType(_currentFilter.entityType),
            selectedCategories: _selectedCategories,
            onSelect: (category) {
              setState(() {
                if (!_selectedCategories.any((c) => c.id == category.id)) {
                  _selectedCategories.add(category);
                }
              });
            },
            onRemove: (category) {
              setState(() {
                _selectedCategories.removeWhere((c) => c.id == category.id);
              });
            },
            onClearAll: () {
              setState(() {
                _selectedCategories.clear();
              });
            },
            searchPlaceholder: 'Выберите категории для фильтрации',
            height: 56,
          ),
          const SizedBox(height: 16),

          // Фильтр по тегам
          TagFilterWidget(
            tagType: _getTagType(_currentFilter.entityType),
            selectedTags: _selectedTags,
            onTagSelect: (tag) {
              setState(() {
                if (!_selectedTags.any((t) => t.id == tag.id)) {
                  _selectedTags.add(tag);
                }
              });
            },
            onTagRemove: (tag) {
              setState(() {
                _selectedTags.removeWhere((t) => t.id == tag.id);
              });
            },
            onClearAll: () {
              setState(() {
                _selectedTags.clear();
              });
            },
            searchPlaceholder: 'Выберите теги для фильтрации',
            height: 56,
          ),
          const SizedBox(height: 16),

          // Остальные общие фильтры
          CheckboxListTile(
            title: const Text('Включать архивированные'),
            value: _getIsArchived(),
            tristate: true,
            onChanged: (value) {
              _setIsArchived(value);
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            title: const Text('Только избранные'),
            value: _getIsFavorite(),
            tristate: true,
            onChanged: (value) {
              _setIsFavorite(value);
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  CategoryType _getCategoryType(UniversalEntityType entityType) {
    switch (entityType) {
      case UniversalEntityType.password:
        return CategoryType.password;
      case UniversalEntityType.note:
        return CategoryType.notes;
      case UniversalEntityType.otp:
        return CategoryType.totp;
      case UniversalEntityType.attachment:
        return CategoryType.mixed; // Или создать отдельный тип для вложений
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
        return TagType.mixed; // Или создать отдельный тип для вложений
    }
  }

  Widget _buildSortingSection() {
    return _buildSection(
      title: 'Сортировка',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Настройки сортировки будут добавлены в следующих версиях',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  bool? _getIsArchived() {
    switch (_currentFilter.entityType) {
      case UniversalEntityType.password:
        return _currentFilter.passwordFilter?.isArchived;
      case UniversalEntityType.note:
        return _currentFilter.notesFilter?.base.isArchived;
      case UniversalEntityType.otp:
        return _currentFilter.otpFilter?.base.isArchived;
      case UniversalEntityType.attachment:
        return _currentFilter.attachmentsFilter?.base.isArchived;
    }
  }

  void _setIsArchived(bool? value) {
    setState(() {
      switch (_currentFilter.entityType) {
        case UniversalEntityType.password:
          _currentFilter = _currentFilter.copyWith(
            passwordFilter:
                _currentFilter.passwordFilter?.copyWith(isArchived: value) ??
                PasswordFilter(isArchived: value),
          );
          break;
        case UniversalEntityType.note:
          final currentFilter = _currentFilter.notesFilter;
          final currentBase = currentFilter?.base ?? const BaseFilter();
          _currentFilter = _currentFilter.copyWith(
            notesFilter: currentFilter?.copyWith(
              base: currentBase.copyWith(isArchived: value),
            ),
          );
          break;
        case UniversalEntityType.otp:
          final currentFilter = _currentFilter.otpFilter;
          final currentBase = currentFilter?.base ?? const BaseFilter();
          _currentFilter = _currentFilter.copyWith(
            otpFilter: currentFilter?.copyWith(
              base: currentBase.copyWith(isArchived: value),
            ),
          );
          break;
        case UniversalEntityType.attachment:
          final currentFilter = _currentFilter.attachmentsFilter;
          final currentBase = currentFilter?.base ?? const BaseFilter();
          _currentFilter = _currentFilter.copyWith(
            attachmentsFilter: currentFilter?.copyWith(
              base: currentBase.copyWith(isArchived: value),
            ),
          );
          break;
      }
    });
  }

  bool? _getIsFavorite() {
    switch (_currentFilter.entityType) {
      case UniversalEntityType.password:
        return _currentFilter.passwordFilter?.isFavorite;
      case UniversalEntityType.note:
        return _currentFilter.notesFilter?.base.isFavorite;
      case UniversalEntityType.otp:
        return _currentFilter.otpFilter?.base.isFavorite;
      case UniversalEntityType.attachment:
        return _currentFilter.attachmentsFilter?.base.isFavorite;
    }
  }

  void _setIsFavorite(bool? value) {
    setState(() {
      switch (_currentFilter.entityType) {
        case UniversalEntityType.password:
          _currentFilter = _currentFilter.copyWith(
            passwordFilter:
                _currentFilter.passwordFilter?.copyWith(isFavorite: value) ??
                PasswordFilter(isFavorite: value),
          );
          break;
        case UniversalEntityType.note:
          final currentFilter = _currentFilter.notesFilter;
          final currentBase = currentFilter?.base ?? const BaseFilter();
          _currentFilter = _currentFilter.copyWith(
            notesFilter: currentFilter?.copyWith(
              base: currentBase.copyWith(isFavorite: value),
            ),
          );
          break;
        case UniversalEntityType.otp:
          final currentFilter = _currentFilter.otpFilter;
          final currentBase = currentFilter?.base ?? const BaseFilter();
          _currentFilter = _currentFilter.copyWith(
            otpFilter: currentFilter?.copyWith(
              base: currentBase.copyWith(isFavorite: value),
            ),
          );
          break;
        case UniversalEntityType.attachment:
          final currentFilter = _currentFilter.attachmentsFilter;
          final currentBase = currentFilter?.base ?? const BaseFilter();
          _currentFilter = _currentFilter.copyWith(
            attachmentsFilter: currentFilter?.copyWith(
              base: currentBase.copyWith(isFavorite: value),
            ),
          );
          break;
      }
    });
  }

  String _getModalTitle(UniversalEntityType entityType) {
    switch (entityType) {
      case UniversalEntityType.password:
        return 'Фильтры паролей';
      case UniversalEntityType.note:
        return 'Фильтры заметок';
      case UniversalEntityType.otp:
        return 'Фильтры OTP';
      case UniversalEntityType.attachment:
        return 'Фильтры вложений';
    }
  }

  String _getSearchHint(UniversalEntityType entityType) {
    switch (entityType) {
      case UniversalEntityType.password:
        return 'Поиск по названию, логину, URL, заметкам...';
      case UniversalEntityType.note:
        return 'Поиск по заголовку, содержимому...';
      case UniversalEntityType.otp:
        return 'Поиск по issuer, аккаунту...';
      case UniversalEntityType.attachment:
        return 'Поиск по имени файла, описанию...';
    }
  }
}
