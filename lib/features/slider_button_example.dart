import 'package:flutter/material.dart';
import '../common/slider_button.dart';

/// Экран-пример для демонстрации SliderButton компонента
class SliderButtonExampleScreen extends StatefulWidget {
  const SliderButtonExampleScreen({super.key});

  @override
  State<SliderButtonExampleScreen> createState() =>
      _SliderButtonExampleScreenState();
}

class _SliderButtonExampleScreenState extends State<SliderButtonExampleScreen> {
  String _lastAction = 'Никаких действий пока не выполнено';

  void _onSlideComplete(String action) {
    setState(() {
      _lastAction = action;
    });

    // Показываем snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Выполнено: $action'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Slider Button Examples'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Информация о последнем действии
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Последнее действие:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lastAction,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Заголовок секции
            Text(
              'Основные типы Slider Button:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 16),

            // Confirm button
            SliderButton(
              type: SliderButtonType.confirm,
              text: 'Проведите для подтверждения',
              onSlideComplete: () => _onSlideComplete('Подтверждение'),
            ),

            const SizedBox(height: 16),

            // Delete button
            SliderButton(
              type: SliderButtonType.delete,
              text: 'Проведите для удаления',
              onSlideComplete: () => _onSlideComplete('Удаление'),
            ),

            const SizedBox(height: 16),

            // Unlock button
            SliderButton(
              type: SliderButtonType.unlock,
              text: 'Проведите для разблокировки',
              onSlideComplete: () => _onSlideComplete('Разблокировка'),
            ),

            const SizedBox(height: 16),

            // Send button
            SliderButton(
              type: SliderButtonType.send,
              text: 'Проведите для отправки',
              onSlideComplete: () => _onSlideComplete('Отправка'),
            ),

            const SizedBox(height: 32),

            // Заголовок кастомной секции
            Text(
              'Кастомная тема:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 16),

            // Custom themed button
            SliderButtonTheme(
              data: SliderButtonThemeData(
                backgroundColor: Colors.purple.shade100,
                fillColor: Colors.purple.shade600,
                thumbColor: Colors.purple.shade800,
                iconColor: Colors.white,
                textColor: Colors.purple.shade900,
                height: 70.0,
                borderRadius: 35.0,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                thumbSize: 56.0,
                animationDuration: const Duration(milliseconds: 400),
                icon: Icons.star_outline,
              ),
              child: SliderButton(
                type: SliderButtonType.confirm,
                text: 'Кастомная тема',
                onSlideComplete: () => _onSlideComplete('Кастомная тема'),
              ),
            ),

            const SizedBox(height: 16),

            // Заголовок отключенных кнопок
            Text(
              'Отключенные кнопки:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 16),

            // Disabled confirm button
            SliderButton(
              type: SliderButtonType.confirm,
              text: 'Отключенное подтверждение',
              enabled: false,
              onSlideComplete: () => _onSlideComplete('Это не должно работать'),
            ),

            const SizedBox(height: 16),

            // Disabled delete button
            SliderButton(
              type: SliderButtonType.delete,
              text: 'Отключенное удаление',
              enabled: false,
              onSlideComplete: () => _onSlideComplete('Это не должно работать'),
            ),

            const SizedBox(height: 16),

            // Disabled unlock button
            SliderButton(
              type: SliderButtonType.unlock,
              text: 'Отключенная разблокировка',
              enabled: false,
              onSlideComplete: () => _onSlideComplete('Это не должно работать'),
            ),
            const Spacer(),

            // Информационная карточка
            Card(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Инструкция',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Проведите ползунок вправо до конца для активации\n'
                      '• Различные типы кнопок имеют разные цвета и иконки\n'
                      '• Кнопки автоматически сбрасываются после выполнения\n'
                      '• Поддерживается тактильная обратная связь',
                      style: Theme.of(context).textTheme.bodyMedium,
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
}
