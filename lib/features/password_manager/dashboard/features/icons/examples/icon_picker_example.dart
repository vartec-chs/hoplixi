import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/services_providers.dart';
import '../widgets/icon_picker_button.dart';

/// Пример использования IconPickerButton
class IconPickerExample extends ConsumerStatefulWidget {
  const IconPickerExample({super.key});

  @override
  ConsumerState<IconPickerExample> createState() => _IconPickerExampleState();
}

class _IconPickerExampleState extends ConsumerState<IconPickerExample> {
  String? _selectedIconId;
  store.IconData? _selectedIconData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пример выбора иконки')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Основной пример
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Базовый пример',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconPickerButton(
                          selectedIconId: _selectedIconId,
                          selectedIcon: _selectedIconData,
                          onIconSelected: _onIconSelected,
                          onIconCleared: _onIconCleared,
                          label: 'Иконка категории',
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_selectedIconData != null) ...[
                                Text(
                                  'Выбрана иконка: ${_selectedIconData!.name}',
                                ),
                                Text('Тип: ${_selectedIconData!.type.name}'),
                                Text(
                                  'Размер: ${_formatFileSize(_selectedIconData!.data.length)}',
                                ),
                              ] else
                                const Text('Иконка не выбрана'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Различные формы и размеры
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Различные формы и размеры',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        // Квадратная форма
                        IconPickerButton(
                          selectedIconId: _selectedIconId,
                          selectedIcon: _selectedIconData,
                          onIconSelected: _onIconSelected,
                          onIconCleared: _onIconCleared,
                          size: 60,
                          label: 'Квадратная',
                          shape: IconPickerButtonShape.square,
                        ),

                        // Скругленная форма
                        IconPickerButton(
                          selectedIconId: _selectedIconId,
                          selectedIcon: _selectedIconData,
                          onIconSelected: _onIconSelected,
                          onIconCleared: _onIconCleared,
                          size: 80,
                          label: 'Скругленная',
                          shape: IconPickerButtonShape.rounded,
                        ),

                        // Круглая форма
                        IconPickerButton(
                          selectedIconId: _selectedIconId,
                          selectedIcon: _selectedIconData,
                          onIconSelected: _onIconSelected,
                          onIconCleared: _onIconCleared,
                          size: 100,
                          label: 'Круглая',
                          shape: IconPickerButtonShape.circle,
                        ),

                        // Без кнопки очистки
                        IconPickerButton(
                          selectedIconId: _selectedIconId,
                          selectedIcon: _selectedIconData,
                          onIconSelected: _onIconSelected,
                          label: 'Без очистки',
                          showClearButton: false,
                        ),

                        // Отключенная
                        IconPickerButton(
                          selectedIconId: _selectedIconId,
                          selectedIcon: _selectedIconData,
                          onIconSelected: _onIconSelected,
                          onIconCleared: _onIconCleared,
                          label: 'Отключена',
                          enabled: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Кнопки для демонстрации
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Управление',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _loadRandomIcon,
                          child: const Text('Загрузить случайную иконку'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _onIconCleared,
                          child: const Text('Очистить'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onIconSelected(String iconId) async {
    try {
      final iconsService = ref.read(iconsServiceProvider);
      final iconData = await iconsService.getIcon(iconId);

      setState(() {
        _selectedIconId = iconId;
        _selectedIconData = iconData;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Выбрана иконка: ${iconData?.name ?? 'Неизвестная'}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки иконки: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _onIconCleared() {
    setState(() {
      _selectedIconId = null;
      _selectedIconData = null;
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Иконка очищена'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _loadRandomIcon() async {
    try {
      final iconsService = ref.read(iconsServiceProvider);
      final allIcons = await iconsService.getAllIcons();

      if (allIcons.isNotEmpty) {
        final randomIcon =
            allIcons[DateTime.now().millisecondsSinceEpoch % allIcons.length];
        setState(() {
          _selectedIconId = randomIcon.id;
          _selectedIconData = randomIcon;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Загружена случайная иконка: ${randomIcon.name}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Нет доступных иконок'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки иконок: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }
}
