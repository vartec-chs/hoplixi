import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/common/text_field.dart';
import 'package:hoplixi/features/password_manager/universal_filter/universal_filter_barrel.dart';
import 'package:hoplixi/hoplixi_store/models/filter/base_filter.dart';
import 'package:hoplixi/hoplixi_store/models/password_filter.dart'
    as password_models
    show PasswordSortField, SortDirection;
import 'package:hoplixi/hoplixi_store/models/password_filter.dart'
    show PasswordFilter;
import 'package:hoplixi/hoplixi_store/models/filter/notes_filter.dart';
import 'package:hoplixi/hoplixi_store/models/filter/otp_filter.dart'
    as otp_filter;
import 'package:hoplixi/hoplixi_store/models/filter/attachments_filter.dart';
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
    final notesFilter =
        _currentFilter.notesFilter ?? const NotesFilter(base: BaseFilter());

    return _buildSection(
      title: 'Фильтры для заметок',
      child: Column(
        children: [
          // Фильтр по заголовку
          TextField(
            decoration: const InputDecoration(
              labelText: 'Фильтр по заголовку',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: notesFilter.title ?? ''),
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  notesFilter: notesFilter.copyWith(
                    title: value.trim().isEmpty ? null : value.trim(),
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 16),

          // Фильтр по содержимому
          TextField(
            decoration: const InputDecoration(
              labelText: 'Фильтр по содержимому',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: notesFilter.content ?? ''),
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  notesFilter: notesFilter.copyWith(
                    content: value.trim().isEmpty ? null : value.trim(),
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 16),

          // Диапазон длины содержимого
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Мин. длина содержимого',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(
                    text: notesFilter.minContentLength?.toString() ?? '',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      final intValue = int.tryParse(value.trim());
                      _currentFilter = _currentFilter.copyWith(
                        notesFilter: notesFilter.copyWith(
                          minContentLength: intValue,
                        ),
                      );
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Макс. длина содержимого',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(
                    text: notesFilter.maxContentLength?.toString() ?? '',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      final intValue = int.tryParse(value.trim());
                      _currentFilter = _currentFilter.copyWith(
                        notesFilter: notesFilter.copyWith(
                          maxContentLength: intValue,
                        ),
                      );
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          CheckboxListTile(
            title: const Text('Только закрепленные'),
            value: notesFilter.base.isPinned,
            tristate: true,
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  notesFilter: notesFilter.copyWith(
                    base: notesFilter.base.copyWith(isPinned: value),
                  ),
                );
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            title: const Text('Только с содержимым'),
            value: notesFilter.hasContent,
            tristate: true,
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  notesFilter: notesFilter.copyWith(hasContent: value),
                );
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            title: const Text('С вложениями'),
            value: notesFilter.hasAttachments,
            tristate: true,
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  notesFilter: notesFilter.copyWith(hasAttachments: value),
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
    final otpFilter =
        _currentFilter.otpFilter ??
        const otp_filter.OtpFilter(base: BaseFilter());

    return _buildSection(
      title: 'Фильтры для OTP',
      child: Column(
        children: [
          // Тип OTP
          DropdownButtonFormField<otp_filter.OtpType?>(
            decoration: primaryInputDecoration(
              context,
              labelText: 'Тип OTP',
            ),
            value: otpFilter.type,
            items: [
              const DropdownMenuItem(value: null, child: Text('Все типы')),
              ...otp_filter.OtpType.values.map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  otpFilter: otpFilter.copyWith(type: value),
                );
              });
            },
          ),
          const SizedBox(height: 16),

          // Фильтр по издателю (issuer)
          TextField(
            decoration: primaryInputDecoration(
              context,
              labelText: 'Издатель (Google, GitHub, и т.д.)',
            ),
            controller: TextEditingController(text: otpFilter.issuer ?? ''),
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  otpFilter: otpFilter.copyWith(
                    issuer: value.trim().isEmpty ? null : value.trim(),
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 16),

          // Фильтр по имени аккаунта
          TextField(
            decoration: const InputDecoration(
              labelText: 'Имя аккаунта',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(
              text: otpFilter.accountName ?? '',
            ),
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  otpFilter: otpFilter.copyWith(
                    accountName: value.trim().isEmpty ? null : value.trim(),
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 16),

          // Количество цифр
          DropdownButtonFormField<int?>(
            decoration: const InputDecoration(
              labelText: 'Количество цифр',
              border: OutlineInputBorder(),
            ),
            value: otpFilter.digits,
            items: const [
              DropdownMenuItem(value: null, child: Text('Любое')),
              DropdownMenuItem(value: 6, child: Text('6 цифр')),
              DropdownMenuItem(value: 8, child: Text('8 цифр')),
            ],
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  otpFilter: otpFilter.copyWith(digits: value),
                );
              });
            },
          ),
          const SizedBox(height: 16),

          // Период для TOTP
          if (otpFilter.type == null ||
              otpFilter.type == otp_filter.OtpType.totp)
            TextField(
              decoration: const InputDecoration(
                labelText: 'Период (секунды)',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(
                text: otpFilter.period?.toString() ?? '',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  final intValue = int.tryParse(value.trim());
                  _currentFilter = _currentFilter.copyWith(
                    otpFilter: otpFilter.copyWith(period: intValue),
                  );
                });
              },
            ),
          if (otpFilter.type == null ||
              otpFilter.type == otp_filter.OtpType.totp)
            const SizedBox(height: 16),

          CheckboxListTile(
            title: const Text('Связан с паролем'),
            value: otpFilter.hasPasswordLink,
            tristate: true,
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  otpFilter: otpFilter.copyWith(hasPasswordLink: value),
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
    final attachmentFilter =
        _currentFilter.attachmentsFilter ??
        const AttachmentsFilter(base: BaseFilter());

    return _buildSection(
      title: 'Фильтры для вложений',
      child: Column(
        children: [
          // Фильтр по имени файла
          TextField(
            decoration: primaryInputDecoration(
              context,
              labelText: 'Имя файла',
            ),
            controller: TextEditingController(
              text: attachmentFilter.name ?? '',
            ),
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  attachmentsFilter: attachmentFilter.copyWith(
                    name: value.trim().isEmpty ? null : value.trim(),
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 16),

          // Фильтр по описанию
          TextField(
            decoration: primaryInputDecoration(
              context,
              labelText: 'Описание',
            ),
            controller: TextEditingController(
              text: attachmentFilter.description ?? '',
            ),
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  attachmentsFilter: attachmentFilter.copyWith(
                    description: value.trim().isEmpty ? null : value.trim(),
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 16),

          // Расширение файла
          TextField(
            decoration: primaryInputDecoration(
              context,
              labelText: 'Расширение файла (pdf, jpg, png)',
            ),
            controller: TextEditingController(
              text: attachmentFilter.fileExtension ?? '',
            ),
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  attachmentsFilter: attachmentFilter.copyWith(
                    fileExtension: value.trim().isEmpty ? null : value.trim(),
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 16),

          // Диапазон размера файла
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Мин. размер (байты)',
                  ),
                  controller: TextEditingController(
                    text: attachmentFilter.minFileSize?.toString() ?? '',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      final intValue = int.tryParse(value.trim());
                      _currentFilter = _currentFilter.copyWith(
                        attachmentsFilter: attachmentFilter.copyWith(
                          minFileSize: intValue,
                        ),
                      );
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Макс. размер (байты)',
                  ),
                  controller: TextEditingController(
                    text: attachmentFilter.maxFileSize?.toString() ?? '',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      final intValue = int.tryParse(value.trim());
                      _currentFilter = _currentFilter.copyWith(
                        attachmentsFilter: attachmentFilter.copyWith(
                          maxFileSize: intValue,
                        ),
                      );
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Тип родительского объекта
          DropdownButtonFormField<AttachmentType?>(
            decoration: primaryInputDecoration(
              context,
              labelText: 'Тип родительского объекта',
            ),
            value: attachmentFilter.attachedToType,
            items: [
              const DropdownMenuItem(value: null, child: Text('Все типы')),
              ...AttachmentType.values.map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(_getAttachmentTypeLabel(type)),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  attachmentsFilter: attachmentFilter.copyWith(
                    attachedToType: value,
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 16),

          CheckboxListTile(
            title: const Text('Есть контрольная сумма'),
            value: attachmentFilter.hasChecksum,
            tristate: true,
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  attachmentsFilter: attachmentFilter.copyWith(
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
      child: Column(
        children: [
          // Направление сортировки
          Row(
            children: [
              Expanded(
                child: Text(
                  'Направление сортировки',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('По возрастанию'),
                    icon: Icon(Icons.arrow_upward, size: 16),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('По убыванию'),
                    icon: Icon(Icons.arrow_downward, size: 16),
                  ),
                ],
                style: SegmentedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                ),
                selected: {_getSortAscending()},
                onSelectionChanged: (Set<bool> selection) {
                  if (selection.isNotEmpty) {
                    _setSortAscending(selection.first);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Поле сортировки
          Row(
            children: [
              Expanded(
                child: Text(
                  'Сортировать по',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              DropdownButton<String>(
                value: _getSortField(),
                items: _getSortOptions().map((option) {
                  return DropdownMenuItem<String>(
                    value: option['value']!,
                    child: Text(option['label']!),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _setSortField(newValue);
                  }
                },
              ),
            ],
          ),
        ],
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

  // Методы для работы с сортировкой
  bool _getSortAscending() {
    switch (_currentFilter.entityType) {
      case UniversalEntityType.password:
        return _currentFilter.passwordFilter?.sortDirection ==
            password_models.SortDirection.asc;
      case UniversalEntityType.note:
        return _currentFilter.notesFilter?.sortDirection == SortDirection.asc;
      case UniversalEntityType.otp:
        return _currentFilter.otpFilter?.sortDirection == SortDirection.asc;
      case UniversalEntityType.attachment:
        return _currentFilter.attachmentsFilter?.sortDirection ==
            SortDirection.asc;
    }
  }

  void _setSortAscending(bool ascending) {
    setState(() {
      switch (_currentFilter.entityType) {
        case UniversalEntityType.password:
          _currentFilter = _currentFilter.copyWith(
            passwordFilter:
                (_currentFilter.passwordFilter ?? const PasswordFilter())
                    .copyWith(
                      sortDirection: ascending
                          ? password_models.SortDirection.asc
                          : password_models.SortDirection.desc,
                    ),
          );
          break;
        case UniversalEntityType.note:
          final currentFilter =
              _currentFilter.notesFilter ??
              const NotesFilter(base: BaseFilter());
          _currentFilter = _currentFilter.copyWith(
            notesFilter: currentFilter.copyWith(
              sortDirection: ascending ? SortDirection.asc : SortDirection.desc,
            ),
          );
          break;
        case UniversalEntityType.otp:
          final currentFilter =
              _currentFilter.otpFilter ??
              const otp_filter.OtpFilter(base: BaseFilter());
          _currentFilter = _currentFilter.copyWith(
            otpFilter: currentFilter.copyWith(
              sortDirection: ascending ? SortDirection.asc : SortDirection.desc,
            ),
          );
          break;
        case UniversalEntityType.attachment:
          final currentFilter =
              _currentFilter.attachmentsFilter ??
              const AttachmentsFilter(base: BaseFilter());
          _currentFilter = _currentFilter.copyWith(
            attachmentsFilter: currentFilter.copyWith(
              sortDirection: ascending ? SortDirection.asc : SortDirection.desc,
            ),
          );
          break;
      }
    });
  }

  String _getSortField() {
    switch (_currentFilter.entityType) {
      case UniversalEntityType.password:
        return _currentFilter.passwordFilter?.sortField?.name ?? 'name';
      case UniversalEntityType.note:
        return _currentFilter.notesFilter?.sortField?.name ?? 'title';
      case UniversalEntityType.otp:
        return _currentFilter.otpFilter?.sortField?.name ?? 'issuer';
      case UniversalEntityType.attachment:
        return _currentFilter.attachmentsFilter?.sortField?.name ?? 'name';
    }
  }

  void _setSortField(String field) {
    setState(() {
      switch (_currentFilter.entityType) {
        case UniversalEntityType.password:
          final sortField = password_models.PasswordSortField.values.firstWhere(
            (f) => f.name == field,
            orElse: () => password_models.PasswordSortField.name,
          );
          _currentFilter = _currentFilter.copyWith(
            passwordFilter:
                (_currentFilter.passwordFilter ?? const PasswordFilter())
                    .copyWith(sortField: sortField),
          );
          break;
        case UniversalEntityType.note:
          final sortField = NotesSortField.values.firstWhere(
            (f) => f.name == field,
            orElse: () => NotesSortField.title,
          );
          final currentFilter =
              _currentFilter.notesFilter ??
              const NotesFilter(base: BaseFilter());
          _currentFilter = _currentFilter.copyWith(
            notesFilter: currentFilter.copyWith(sortField: sortField),
          );
          break;
        case UniversalEntityType.otp:
          final sortField = otp_filter.OtpSortField.values.firstWhere(
            (f) => f.name == field,
            orElse: () => otp_filter.OtpSortField.issuer,
          );
          final currentFilter =
              _currentFilter.otpFilter ??
              const otp_filter.OtpFilter(base: BaseFilter());
          _currentFilter = _currentFilter.copyWith(
            otpFilter: currentFilter.copyWith(sortField: sortField),
          );
          break;
        case UniversalEntityType.attachment:
          final sortField = AttachmentsSortField.values.firstWhere(
            (f) => f.name == field,
            orElse: () => AttachmentsSortField.name,
          );
          final currentFilter =
              _currentFilter.attachmentsFilter ??
              const AttachmentsFilter(base: BaseFilter());
          _currentFilter = _currentFilter.copyWith(
            attachmentsFilter: currentFilter.copyWith(sortField: sortField),
          );
          break;
      }
    });
  }

  String _getAttachmentTypeLabel(AttachmentType type) {
    switch (type) {
      case AttachmentType.password:
        return 'Пароль';
      case AttachmentType.totp:
        return 'TOTP';
      case AttachmentType.note:
        return 'Заметка';
    }
  }

  List<Map<String, String>> _getSortOptions() {
    switch (_currentFilter.entityType) {
      case UniversalEntityType.password:
        return [
          {'value': 'name', 'label': 'Название'},
          {'value': 'createdAt', 'label': 'Дата создания'},
          {'value': 'modifiedAt', 'label': 'Дата изменения'},
          {'value': 'lastAccessed', 'label': 'Последний доступ'},
          {'value': 'usedCount', 'label': 'Частота использования'},
        ];
      case UniversalEntityType.note:
        return [
          {'value': 'title', 'label': 'Заголовок'},
          {'value': 'createdAt', 'label': 'Дата создания'},
          {'value': 'modifiedAt', 'label': 'Дата изменения'},
          {'value': 'lastAccessed', 'label': 'Последний доступ'},
          {'value': 'contentLength', 'label': 'Длина содержимого'},
        ];
      case UniversalEntityType.otp:
        return [
          {'value': 'issuer', 'label': 'Издатель'},
          {'value': 'accountName', 'label': 'Имя аккаунта'},
          {'value': 'createdAt', 'label': 'Дата создания'},
          {'value': 'modifiedAt', 'label': 'Дата изменения'},
          {'value': 'lastAccessed', 'label': 'Последний доступ'},
        ];
      case UniversalEntityType.attachment:
        return [
          {'value': 'name', 'label': 'Название'},
          {'value': 'fileSize', 'label': 'Размер файла'},
          {'value': 'createdAt', 'label': 'Дата создания'},
          {'value': 'modifiedAt', 'label': 'Дата изменения'},
          {'value': 'mimeType', 'label': 'MIME тип'},
        ];
    }
  }
}
