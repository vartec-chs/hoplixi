import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/app/router/routes_path.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/password_manager/new_cloud_sync/models/import_session_state.dart';
import 'package:hoplixi/features/password_manager/new_cloud_sync/providers/import_session_provider.dart';

/// Экран процесса импорта базы данных из облака
class ProcessImportedStoreScreen extends ConsumerStatefulWidget {
  const ProcessImportedStoreScreen({super.key});

  @override
  ConsumerState<ProcessImportedStoreScreen> createState() =>
      _ProcessImportedStoreScreenState();
}

class _ProcessImportedStoreScreenState
    extends ConsumerState<ProcessImportedStoreScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Запускаем импорт автоматически при открытии экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(importSessionProvider.notifier).executeImport();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(importSessionProvider);

    // Слушаем изменения состояния для навигации
    ref.listen(importSessionProvider, (previous, next) async {
      if (next?.currentStep == ImportStep.completed) {
        // Импорт завершён успешно - небольшая задержка для отображения успеха
        // После этого возвращаемся на dashboard
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          logInfo(
            'Переход на dashboard после успешного импорта',
            tag: 'ProcessImportedStoreScreen',
          );
          context.go(AppRoutes.dashboard);
        }
      }
    });

    if (sessionState == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Импорт хранилища')),
        body: const Center(child: Text('Сессия импорта не инициализирована')),
      );
    }

    return PopScope(
      canPop:
          sessionState.currentStep == ImportStep.error ||
          sessionState.currentStep == ImportStep.completed,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Импорт хранилища'),
          automaticallyImplyLeading:
              sessionState.currentStep == ImportStep.error,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Название хранилища
              Text(
                sessionState.metadata.name,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Индикатор прогресса
              _buildProgressIndicator(sessionState),
              const SizedBox(height: 24),

              // Текущий этап
              _buildStepIndicator(sessionState),
              const SizedBox(height: 16),

              // Сообщение о прогрессе
              Text(
                sessionState.message,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Поле ввода пароля (если требуется)
              if (sessionState.currentStep == ImportStep.opening &&
                  sessionState.message.contains('Требуется ввод'))
                _buildPasswordInput(sessionState),

              // Кнопка действия при ошибке
              if (sessionState.currentStep == ImportStep.error)
                _buildErrorActions(context, sessionState),
            ],
          ),
        ),
      ),
    );
  }

  /// Индикатор прогресса
  Widget _buildProgressIndicator(ImportSessionState state) {
    if (state.currentStep == ImportStep.error) {
      return const Icon(Icons.error_outline, size: 64, color: Colors.red);
    }

    if (state.currentStep == ImportStep.completed) {
      return const Icon(
        Icons.check_circle_outline,
        size: 64,
        color: Colors.green,
      );
    }

    return Column(
      children: [
        CircularProgressIndicator(value: state.progress, strokeWidth: 6),
        const SizedBox(height: 16),
        Text(
          '${(state.progress * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }

  /// Индикатор текущего этапа
  Widget _buildStepIndicator(ImportSessionState state) {
    String stepText;
    IconData stepIcon;

    switch (state.currentStep) {
      case ImportStep.checking:
        stepText = 'Проверка обновлений';
        stepIcon = Icons.search;
        break;
      case ImportStep.downloading:
        stepText = 'Скачивание';
        stepIcon = Icons.download;
        break;
      case ImportStep.replacing:
        stepText = 'Замена базы данных';
        stepIcon = Icons.sync;
        break;
      case ImportStep.opening:
        stepText = 'Открытие базы данных';
        stepIcon = Icons.lock_open;
        break;
      case ImportStep.completed:
        stepText = 'Завершено';
        stepIcon = Icons.check_circle;
        break;
      case ImportStep.error:
        stepText = 'Ошибка';
        stepIcon = Icons.error;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(stepIcon, size: 28),
        const SizedBox(width: 12),
        Text(stepText, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }

  /// Поле ввода пароля
  Widget _buildPasswordInput(ImportSessionState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Мастер-пароль',
            hintText: 'Введите пароль от базы данных',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          autofocus: true,
          onSubmitted: (_) => _submitPassword(state),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _submitPassword(state),
          icon: const Icon(Icons.lock_open),
          label: const Text('Открыть базу данных'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  /// Кнопки при ошибке
  Widget _buildErrorActions(BuildContext context, ImportSessionState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.error != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              state.error!,
              style: TextStyle(color: Colors.red.shade900),
            ),
          ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            ref.read(importSessionProvider.notifier).executeImport();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Повторить попытку'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            ref.read(importSessionProvider.notifier).reset();
            context.go(AppRoutes.dashboard);
          },
          icon: const Icon(Icons.close),
          label: const Text('Отменить'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  /// Отправка пароля
  void _submitPassword(ImportSessionState state) {
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите пароль')));
      return;
    }

    if (state.importedDbPath == null) {
      logError(
        'Путь к импортированной БД не найден',
        tag: 'ProcessImportedStoreScreen',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: путь к БД не определён')),
      );
      return;
    }

    ref
        .read(importSessionProvider.notifier)
        .openWithPassword(password, state.importedDbPath!);
  }
}
