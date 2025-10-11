import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/global/providers/biometric_auto_open_provider.dart';
import 'package:hoplixi/features/global/providers/biometric_provider.dart';
import 'package:hoplixi/features/global/widgets/index.dart';
import 'package:hoplixi/hoplixi_store/services/biometric_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  BiometricStatus? _biometricStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadBiometricStatus();
    });
  }

  Future<void> _loadBiometricStatus() async {
    final biometricService = ref.read(biometricServiceProvider);
    final result = await biometricService.checkBiometricStatus();
    setState(() {
      _biometricStatus = result.success
          ? result.data
          : BiometricStatus.notSupported;
    });
  }

  String _getBiometricStatusMessage() {
    if (_biometricStatus == null) return 'Проверка...';
    switch (_biometricStatus!) {
      case BiometricStatus.notSupported:
        return 'Биометрия не поддерживается устройством';
      case BiometricStatus.notAvailable:
        return 'Биометрия недоступна';

      case BiometricStatus.noBiometricsEnrolled:
        return 'Нет зарегистрированных биометрических данных';
      case BiometricStatus.lockedOut:
        return 'Биометрия заблокирована из-за слишком большого количества неудачных попыток. Попробуйте позже.';
      case BiometricStatus.ready:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: Consumer(
            builder: (context, ref, child) {
              final biometricAutoOpenAsync = ref.watch(
                biometricAutoOpenProvider,
              );
              return biometricAutoOpenAsync.when(
                data: (biometricAutoOpen) => Column(
                  spacing: 8,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Автоматически открывать последний хранилище
                    SwitchListTile(
                      title: const Text(
                        'Автоматически открывать последний хранилище',
                      ),
                      value: Prefs.get<bool>(Keys.autoOpenLastStorage) ?? false,
                      onChanged: (value) async {
                        logDebug(
                          'Attempting to change auto-open setting to $value $biometricAutoOpen',
                          tag: 'SettingsScreen',
                        );
                        if (biometricAutoOpen) {
                          final biometricService = ref.read(
                            biometricServiceProvider,
                          );
                          final result = await biometricService
                              .authenticateWithBiometrics(
                                localizedReason:
                                    'Подтвердите изменение настройки автооткрытия',
                              );
                          logDebug(
                            'Biometric auth result: ${result.data}',
                            tag: 'SettingsScreen',
                          );
                          if (!result.success ||
                              result.data !=
                                  BiometricAuthResult.authenticated) {
                            ToastHelper.error(
                              title: 'Ошибка',
                              description:
                                  'Не удалось подтвердить изменение настройки',
                            );
                            return;
                          }
                        }
                        Prefs.set(Keys.autoOpenLastStorage, value);
                        setState(() {});
                      },
                    ),

                    // Использовать биометрию для подтверждения изменения автооткрытия
                    SwitchListTile(
                      title: const Text(
                        'Использовать биометрию для подтверждения изменения автооткрытия',
                      ),
                      subtitle: _biometricStatus != BiometricStatus.ready
                          ? Text(_getBiometricStatusMessage())
                          : null,
                      value: biometricAutoOpen,
                      onChanged: _biometricStatus == BiometricStatus.ready
                          ? (value) async {
                              final biometricService = ref.read(
                                biometricServiceProvider,
                              );
                              final result = await biometricService
                                  .authenticateWithBiometrics(
                                    localizedReason:
                                        'Подтвердите изменение настройки биометрии для автооткрытия',
                                  );
                              if (!result.success ||
                                  result.data !=
                                      BiometricAuthResult.authenticated) {
                                ToastHelper.error(
                                  title: 'Ошибка',
                                  description:
                                      'Не удалось подтвердить изменение настройки',
                                );
                                return;
                              }
                              await ref
                                  .read(biometricAutoOpenProvider.notifier)
                                  .setBiometricAutoOpen(value);
                              setState(() {});
                            }
                          : null,
                    ),
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

                    // Настройки уведомлений
                    // const NotificationSettingsWidget(),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: Text('Ошибка загрузки настроек: $error')),
              );
            },
          ),
        ),
      ),
    );
  }
}
