import 'package:flutter/material.dart';
import '../common/slider_button.dart';

/// Расширенные примеры использования SliderButton
class SliderButtonAdvancedExamples extends StatefulWidget {
  const SliderButtonAdvancedExamples({super.key});

  @override
  State<SliderButtonAdvancedExamples> createState() =>
      _SliderButtonAdvancedExamplesState();
}

class _SliderButtonAdvancedExamplesState
    extends State<SliderButtonAdvancedExamples> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Расширенные примеры SliderButton')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Секция 1: Различные размеры
            _buildSection(context, 'Различные размеры', [
              SliderButtonTheme(
                data: SliderButtonThemes.confirm(context).copyWith(
                  height: 45.0,
                  thumbSize: 35.0,
                  textStyle: const TextStyle(fontSize: 14),
                ),
                child: SliderButton(
                  type: SliderButtonType.confirm,
                  text: 'Маленькая кнопка',
                  onSlideComplete: () {},
                ),
              ),
              const SizedBox(height: 12),
              SliderButton(
                type: SliderButtonType.confirm,
                text: 'Стандартная кнопка',
                onSlideComplete: () {},
              ),
              const SizedBox(height: 12),
              SliderButtonTheme(
                data: SliderButtonThemes.confirm(context).copyWith(
                  height: 80.0,
                  thumbSize: 64.0,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: SliderButton(
                  type: SliderButtonType.confirm,
                  text: 'Большая кнопка',
                  onSlideComplete: () {},
                ),
              ),
            ]),

            const SizedBox(height: 32),

            // Секция 2: Различные скорости анимации
            _buildSection(context, 'Различные скорости анимации', [
              SliderButtonTheme(
                data: SliderButtonThemes.unlock(context).copyWith(
                  animationDuration: const Duration(milliseconds: 100),
                ),
                child: SliderButton(
                  type: SliderButtonType.unlock,
                  text: 'Быстрая анимация (100ms)',
                  onSlideComplete: () {},
                ),
              ),
              const SizedBox(height: 12),
              SliderButtonTheme(
                data: SliderButtonThemes.unlock(context).copyWith(
                  animationDuration: const Duration(milliseconds: 800),
                ),
                child: SliderButton(
                  type: SliderButtonType.unlock,
                  text: 'Медленная анимация (800ms)',
                  onSlideComplete: () {},
                ),
              ),
            ]),

            const SizedBox(height: 32),

            // Секция 3: Различные формы
            _buildSection(context, 'Различные формы', [
              SliderButtonTheme(
                data: SliderButtonThemes.send(
                  context,
                ).copyWith(borderRadius: 8.0),
                child: SliderButton(
                  type: SliderButtonType.send,
                  text: 'Прямоугольная форма',
                  onSlideComplete: () {},
                ),
              ),
              const SizedBox(height: 12),
              SliderButtonTheme(
                data: SliderButtonThemes.send(
                  context,
                ).copyWith(borderRadius: 15.0),
                child: SliderButton(
                  type: SliderButtonType.send,
                  text: 'Слегка скругленная',
                  onSlideComplete: () {},
                ),
              ),
              const SizedBox(height: 12),
              SliderButton(
                type: SliderButtonType.send,
                text: 'Сильно скругленная (по умолчанию)',
                onSlideComplete: () {},
              ),
            ]),

            const SizedBox(height: 32),

            // Секция 4: Кастомные цветовые схемы
            _buildSection(context, 'Кастомные цветовые схемы', [
              // Градиентная тема
              SliderButtonTheme(
                data: SliderButtonThemeData(
                  backgroundColor: Colors.grey.shade200,
                  fillColor: Colors.orange.shade600,
                  thumbColor: Colors.deepOrange.shade700,
                  iconColor: Colors.white,
                  textColor: Colors.grey.shade800,
                  height: 60.0,
                  borderRadius: 30.0,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  thumbSize: 48.0,
                  animationDuration: const Duration(milliseconds: 300),
                  icon: Icons.whatshot,
                ),
                child: SliderButton(
                  type: SliderButtonType.confirm,
                  text: 'Огненная тема',
                  onSlideComplete: () {},
                ),
              ),
              const SizedBox(height: 12),

              // Морская тема
              SliderButtonTheme(
                data: SliderButtonThemeData(
                  backgroundColor: Colors.blue.shade50,
                  fillColor: Colors.blue.shade700,
                  thumbColor: Colors.lightBlue.shade800,
                  iconColor: Colors.white,
                  textColor: Colors.blue.shade900,
                  height: 60.0,
                  borderRadius: 30.0,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  thumbSize: 48.0,
                  animationDuration: const Duration(milliseconds: 300),
                  icon: Icons.waves,
                ),
                child: SliderButton(
                  type: SliderButtonType.confirm,
                  text: 'Морская тема',
                  onSlideComplete: () {},
                ),
              ),
              const SizedBox(height: 12),

              // Темная тема
              SliderButtonTheme(
                data: SliderButtonThemeData(
                  backgroundColor: Colors.grey.shade900,
                  fillColor: Colors.grey.shade700,
                  thumbColor: Colors.white,
                  iconColor: Colors.grey.shade900,
                  textColor: Colors.white,
                  height: 60.0,
                  borderRadius: 30.0,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  thumbSize: 48.0,
                  animationDuration: const Duration(milliseconds: 300),
                  icon: Icons.dark_mode,
                ),
                child: SliderButton(
                  type: SliderButtonType.confirm,
                  text: 'Темная тема',
                  onSlideComplete: () {},
                ),
              ),
            ]),

            const SizedBox(height: 32),

            // Секция 5: Различные иконки
            _buildSection(context, 'Различные иконки', [
              SliderButtonTheme(
                data: SliderButtonThemes.confirm(
                  context,
                ).copyWith(icon: Icons.thumb_up),
                child: SliderButton(
                  type: SliderButtonType.confirm,
                  text: 'Лайк',
                  onSlideComplete: () {},
                ),
              ),
              const SizedBox(height: 12),
              SliderButtonTheme(
                data: SliderButtonThemes.confirm(context).copyWith(
                  icon: Icons.favorite,
                  fillColor: Colors.pink.shade600,
                  thumbColor: Colors.pink.shade700,
                ),
                child: SliderButton(
                  type: SliderButtonType.confirm,
                  text: 'Добавить в избранное',
                  onSlideComplete: () {},
                ),
              ),
              const SizedBox(height: 12),
              SliderButtonTheme(
                data: SliderButtonThemes.confirm(context).copyWith(
                  icon: Icons.download,
                  fillColor: Colors.green.shade600,
                  thumbColor: Colors.green.shade700,
                ),
                child: SliderButton(
                  type: SliderButtonType.confirm,
                  text: 'Скачать',
                  onSlideComplete: () {},
                ),
              ),
            ]),

            const SizedBox(height: 32),

            // Информация об использовании
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Как использовать SliderButton:',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '''
1. Базовое использование:
   SliderButton(
     type: SliderButtonType.confirm,
     text: 'Ваш текст',
     onSlideComplete: () => yourFunction(),
   )

2. С кастомной темой:
   SliderButtonTheme(
     data: SliderButtonThemes.delete(context),
     child: SliderButton(...),
   )

3. Полностью кастомная тема:
   SliderButtonTheme(
     data: SliderButtonThemeData(
       backgroundColor: Colors.blue,
       fillColor: Colors.green,
       // ... другие параметры
     ),
     child: SliderButton(...),
   )

Доступные типы:
• SliderButtonType.confirm - для подтверждения
• SliderButtonType.delete - для удаления
• SliderButtonType.unlock - для разблокировки
• SliderButtonType.send - для отправки
                      ''',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontFamily: 'monospace',
                      ),
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

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}
