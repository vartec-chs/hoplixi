import 'package:flutter/material.dart';
import 'index.dart';

/// Пример использования автоматической системы настроек
class AutoPreferencesExample extends StatelessWidget {
  const AutoPreferencesExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Preferences Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  final AutoPreferencesManager _manager = AutoPreferencesManager.instance;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  void _initializeSettings() {
    // Инициализируем настройки
    AppSettingsDefinition.initialize();

    // Добавляем слушателей для демонстрации
    _manager.addListener('theme_mode', (value) {
      print('Тема изменена: $value');
    });

    _manager.addListener('auto_lock_timeout', (value) {
      print('Таймаут автоблокировки изменен: $value минут');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Preferences Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Пример автоматической системы настроек',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Эта система позволяет описывать настройки декларативно '
              'и автоматически генерировать интерфейс.',
            ),
            const SizedBox(height: 24),

            // Демонстрация получения значений
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Текущие значения настроек:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<Map<String, String>>(
                      future: _getCurrentSettings(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: snapshot.data!.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Text('${entry.key}: ${entry.value}'),
                              );
                            }).toList(),
                          );
                        }
                        return const CircularProgressIndicator();
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Кнопки для демонстрации
            ElevatedButton.icon(
              onPressed: () => _openSettingsScreen(context),
              icon: const Icon(Icons.settings),
              label: const Text('Открыть настройки'),
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: _demonstrateApiUsage,
              icon: const Icon(Icons.code),
              label: const Text('Демонстрация API'),
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: _resetAllSettings,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Сбросить настройки'),
            ),

            const Spacer(),

            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Настройки автоматически сохраняются в SharedPreferences '
                  'и сохраняются между запусками приложения.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, String>> _getCurrentSettings() async {
    final settings = <String, String>{};

    try {
      settings['Режим темы'] = _manager.getValue<String>(
        'theme_mode',
        defaultValue: 'system',
      );
      settings['Автоблокировка'] = _manager
          .getValue<bool>('auto_lock_enabled')
          .toString();
      settings['Таймаут (мин)'] = _manager
          .getValue<int>('auto_lock_timeout')
          .toString();
      settings['Биометрия'] = _manager
          .getValue<bool>('biometric_enabled')
          .toString();
      settings['Компактный режим'] = _manager
          .getValue<bool>('compact_mode')
          .toString();
      settings['Длина пароля'] = _manager
          .getValue<int>('password_length')
          .toString();
    } catch (e) {
      settings['Ошибка'] = e.toString();
    }

    return settings;
  }

  void _openSettingsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AutoSettingsScreen()),
    ).then((_) {
      // Обновляем интерфейс после возврата из настроек
      setState(() {});
    });
  }

  void _demonstrateApiUsage() async {
    try {
      // Демонстрация программного изменения настроек

      // Переключаем автоблокировку
      final currentAutoLock = _manager.getValue<bool>('auto_lock_enabled');
      await _manager.setValue('auto_lock_enabled', !currentAutoLock);

      // Увеличиваем таймаут на 1 минуту
      final currentTimeout = _manager.getValue<int>('auto_lock_timeout');
      await _manager.setValue('auto_lock_timeout', currentTimeout + 1);

      // Меняем режим темы
      final currentTheme = _manager.getValue<String>('theme_mode');
      final newTheme = currentTheme == 'light' ? 'dark' : 'light';
      await _manager.setValue('theme_mode', newTheme);

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Настройки изменены программно'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  void _resetAllSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сброс настроек'),
        content: const Text(
          'Вы действительно хотите сбросить все настройки к значениям по умолчанию?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _manager.resetAllSettings();
        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Все настройки сброшены')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Ошибка сброса: $e')));
        }
      }
    }
  }
}
