import 'package:flutter/material.dart';
import 'package:hoplixi/common/slider_button.dart';

void main() {
  runApp(const SliderButtonTestApp());
}

class SliderButtonTestApp extends StatelessWidget {
  const SliderButtonTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slider Button Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SliderButtonTestScreen(),
    );
  }
}

class SliderButtonTestScreen extends StatefulWidget {
  const SliderButtonTestScreen({super.key});

  @override
  State<SliderButtonTestScreen> createState() => _SliderButtonTestScreenState();
}

class _SliderButtonTestScreenState extends State<SliderButtonTestScreen> {
  String _lastAction = 'Никаких действий пока не выполнено';

  void _onSlideComplete(String action) {
    setState(() {
      _lastAction = 'Выполнено: $action';
    });

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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Slider Button Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Последнее действие
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _lastAction,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Активные кнопки
            Text(
              'Активные кнопки:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 16),

            SliderButton(
              type: SliderButtonType.confirm,
              text: 'Подтвердить',
              onSlideComplete: () => _onSlideComplete('Подтверждение'),
            ),

            const SizedBox(height: 16),

            SliderButton(
              type: SliderButtonType.delete,
              text: 'Удалить',
              onSlideComplete: () => _onSlideComplete('Удаление'),
            ),

            const SizedBox(height: 24),

            // Отключенные кнопки
            Text(
              'Отключенные кнопки (прозрачность + иконка замочка):',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 16),

            SliderButton(
              type: SliderButtonType.confirm,
              text: 'Подтвердить (отключено)',
              enabled: false,
              onSlideComplete: () => _onSlideComplete('Это не должно работать'),
            ),

            const SizedBox(height: 16),

            SliderButton(
              type: SliderButtonType.delete,
              text: 'Удалить (отключено)',
              enabled: false,
              onSlideComplete: () => _onSlideComplete('Это не должно работать'),
            ),

            const SizedBox(height: 16),

            SliderButton(
              type: SliderButtonType.unlock,
              text: 'Разблокировать (отключено)',
              enabled: false,
              onSlideComplete: () => _onSlideComplete('Это не должно работать'),
            ),

            const Spacer(),

            // Информация
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
                          'Улучшения для отключенных кнопок:',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Прозрачность 50% для всей кнопки\n'
                      '• Фон кнопки с прозрачностью 30%\n'
                      '• Заливка при движении с прозрачностью 30%\n'
                      '• Ползунок с прозрачностью 30%\n'
                      '• Иконка замочка перед текстом\n'
                      '• Убрана тень у ползунка\n'
                      '• Добавлена рамка с прозрачностью 30%',
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
