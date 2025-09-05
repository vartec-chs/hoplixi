import 'package:flutter/material.dart';
import 'package:hoplixi/core/preferences/index.dart';

/// Демонстрационное приложение для показа работы динамических настроек
class PreferencesDemo extends StatelessWidget {
  const PreferencesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hoplixi Preferences Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  final AppPreferences _prefs = AppPreferences.instance;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    await AppPreferences.init();
    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoplixi Preferences Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Информация о приложении
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Демонстрация системы настроек Hoplixi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Первый запуск: ${_prefs.isFirstLaunch ? "Да" : "Нет"}',
                    ),
                    Text('Режим темы: ${_prefs.themeMode.name}'),
                    Text('Язык: ${_prefs.language}'),
                    Text(
                      'Количество настроек: ${_prefs.getAllSettings().length}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Кнопки действий
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DynamicSettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text('Открыть настройки'),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsDemo()),
                );
              },
              icon: const Icon(Icons.dashboard),
              label: const Text('Старые настройки (для сравнения)'),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _addTestData,
              icon: const Icon(Icons.data_object),
              label: const Text('Добавить тестовые данные'),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _showQuickStats,
              icon: const Icon(Icons.info),
              label: const Text('Показать статистику'),
            ),

            const SizedBox(height: 24),

            // Быстрые настройки
            const Text(
              'Быстрые настройки:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              title: const Text('Биометрическая аутентификация'),
              subtitle: const Text('Использовать отпечаток пальца или Face ID'),
              value: _prefs.isBiometricEnabled,
              onChanged: (value) async {
                await _prefs.setBiometricEnabled(value);
                setState(() {});
              },
            ),

            SwitchListTile(
              title: const Text('Автоблокировка'),
              subtitle: const Text('Автоматически блокировать приложение'),
              value: _prefs.isAutoLockEnabled,
              onChanged: (value) async {
                await _prefs.setAutoLockEnabled(value);
                setState(() {});
              },
            ),

            ListTile(
              title: const Text('Длина пароля'),
              subtitle: Text('${_prefs.passwordLength} символов'),
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: _prefs.passwordLength.toDouble(),
                  min: 4,
                  max: 64,
                  divisions: 60,
                  label: _prefs.passwordLength.toString(),
                  onChanged: (value) async {
                    await _prefs.setPasswordLength(value.round());
                    setState(() {});
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTestData() async {
    // Добавляем тестовые хранилища
    await _prefs.addRecentStore('/test/database1.hpx');
    await _prefs.addRecentStore('/test/database2.hpx');
    await _prefs.addRecentStore('/test/database3.hpx');

    // Устанавливаем тестовые настройки
    await _prefs.setDefaultStorePath('/test/default.hpx');
    await _prefs.setAutoBackupEnabled(true);
    await _prefs.setBackupFrequency(3);
    await _prefs.setLastBackupDate(DateTime.now());

    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тестовые данные добавлены')),
      );
    }
  }

  void _showQuickStats() {
    final allSettings = _prefs.getAllSettings();
    final registry = PreferencesRegistry.getAllPreferences();
    final categories = PreferencesRegistry.getAllCategories();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Статистика настроек'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📁 Категорий: ${categories.length}'),
            Text('⚙️ Определений настроек: ${registry.length}'),
            Text('💾 Сохраненных значений: ${allSettings.length}'),
            Text(
              '⚠️ Устаревших: ${registry.where((p) => p.isDeprecated).length}',
            ),
            Text(
              '🔒 Только для чтения: ${registry.where((p) => p.isReadOnly).length}',
            ),
            const SizedBox(height: 16),
            const Text(
              'Категории:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...categories.map(
              (cat) => Text('• ${cat.title} (${cat.preferences.length})'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}
