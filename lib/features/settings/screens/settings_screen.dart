import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_preferences/app_preferences.dart';
import 'package:hoplixi/core/app_preferences/keys.dart';
import 'package:hoplixi/features/global/widgets/index.dart';
import 'package:hoplixi/features/settings/widgets/notification_settings_widget.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Автоматически открывать последний хранилище
            SwitchListTile(
              title: const Text('Автоматически открывать последний хранилище'),
              value: Prefs.get<bool>(Keys.autoOpenLastStorage) ?? false,
              onChanged: (value) {
                Prefs.set(Keys.autoOpenLastStorage, value);
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            // Режим темы
            DropdownButtonFormField<String>(
              initialValue:
                  [
                    'light',
                    'dark',
                    'system',
                  ].contains(Prefs.get<String>(Keys.themeMode))
                  ? Prefs.get<String>(Keys.themeMode)
                  : 'system',
              items: ['light', 'dark', 'system'].map((mode) {
                return DropdownMenuItem(value: mode, child: Text(mode));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  Prefs.set(Keys.themeMode, value);
                  setState(() {});
                }
              },
              decoration: primaryInputDecoration(
                context,
                labelText: 'Режим темы',
              ),
            ),
            const SizedBox(height: 16),
            // Режим домашнего экрана
            DropdownButtonFormField<String>(
              initialValue:
                  Prefs.get<String>(Keys.homeScreenMode) ??
                  HomeScreenMode.singleDB.toString(),
              items: HomeScreenMode.values.map((mode) {
                return DropdownMenuItem(
                  value: mode.toString(),
                  child: Text(mode.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  Prefs.set(Keys.homeScreenMode, value);
                  setState(() {});
                }
              },
              decoration: primaryInputDecoration(
                context,
                labelText: 'Режим домашнего экрана',
              ),
            ),
            const SizedBox(height: 32),
            // Настройки уведомлений
            // const NotificationSettingsWidget(),
          ],
        ),
      ),
    );
  }
}
