import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/global/widgets/button.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/before_opening/create_store/create_store_control.dart';
import 'package:hoplixi/features/password_manager/before_opening/create_store/widgets/step_1_basic_info.dart';
import 'package:hoplixi/features/password_manager/before_opening/create_store/widgets/step_2_security.dart';
import 'package:hoplixi/features/password_manager/before_opening/create_store/widgets/step_3_storage_path.dart';
import 'package:hoplixi/features/password_manager/before_opening/create_store/widgets/step_4_confirmation.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';
import 'package:hoplixi/router/routes_path.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/hoplixi_store/models/db_state.dart';

class CreateStoreScreen extends ConsumerStatefulWidget {
  const CreateStoreScreen({super.key});

  @override
  ConsumerState<CreateStoreScreen> createState() => _CreateStoreScreenState();
}

class _CreateStoreScreenState extends ConsumerState<CreateStoreScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _masterPasswordController;
  late final TextEditingController _confirmPasswordController;

  // Список заголовков шагов
  final List<String> _stepTitles = [
    'Информация',
    'Безопасность',
    'Путь',
    'Подтверждение',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _masterPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    // Очищаем все контроллеры
    _nameController.clear();
    _descriptionController.clear();
    _masterPasswordController.clear();
    _confirmPasswordController.clear();

    // Освобождаем ресурсы
    _nameController.dispose();
    _descriptionController.dispose();
    _masterPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return Step1BasicInfo(
          nameController: _nameController,
          descriptionController: _descriptionController,
        );
      case 1:
        return Step2Security(
          masterPasswordController: _masterPasswordController,
          confirmPasswordController: _confirmPasswordController,
        );
      case 2:
        return const Step3StoragePath();
      case 3:
        return const Step4Confirmation();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(createStoreControllerProvider);
    final controller = ref.read(createStoreControllerProvider.notifier);
    final isReady = ref.watch(createStoreReadyProvider);
    final currentStep = formState.currentStep;
    final isLastStep = currentStep == 3;
    final isFirstStep = currentStep == 0;

    // Слушаем изменения состояния базы данных
    ref.listen<AsyncValue<DatabaseState>>(hoplixiStoreProvider, (
      previous,
      next,
    ) {
      if (next.isLoading) {
        controller.setLoading(true);
      } else {
        controller.setLoading(false);
      }
      if (next.value?.isOpen == true &&
          previous?.value?.status != next.value?.status) {
        // База данных успешно создана, очищаем данные и переходим на главный экран
        controller.clearAllData();

        // Очищаем текстовые контроллеры
        _nameController.clear();
        _descriptionController.clear();
        _masterPasswordController.clear();
        _confirmPasswordController.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ToastHelper.success(
            title: 'Успех',
            description: 'Хранилище успешно создано!',
          );
          context.go(AppRoutes.dashboard);
        });
      }
    });

    // Показываем ошибки
    if (formState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ToastHelper.error(
          title: 'Ошибка',
          description: formState.errorMessage!,
        );
        controller.clearError();
      });
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Очищаем данные при системной навигации назад
          ref.read(createStoreControllerProvider.notifier).clearAllData();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Создать хранилище'),
          surfaceTintColor: Colors.transparent,
          leading: BackButton(
            onPressed: () {
              // Очищаем данные перед уходом с экрана
              ref.read(createStoreControllerProvider.notifier).clearAllData();
              context.go(AppRoutes.home);
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Индикатор прогресса шагов
              _buildStepIndicator(currentStep),

              const SizedBox(height: 16),

              // Контент текущего шага
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: _buildStepContent(currentStep),
                  ),
                ),
              ),

              // Навигационные кнопки
              _buildNavigationButtons(
                context,
                controller,
                isFirstStep,
                isLastStep,
                formState.isLoading,
                isReady,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: List.generate(
          _stepTitles.length,
          (index) => Expanded(child: _buildStepItem(index, currentStep)),
        ),
      ),
    );
  }

  Widget _buildStepItem(int index, int currentStep) {
    final isActive = index == currentStep;
    final isCompleted = index < currentStep;
    final controller = ref.read(createStoreControllerProvider.notifier);

    return InkWell(
      onTap: () {
        // Разрешаем переход только на уже пройденные шаги или текущий
        if (index <= currentStep) {
          controller.goToStep(index);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          children: [
            Row(
              children: [
                // Кружок с номером/галочкой
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : isActive
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainer,
                    border: Border.all(
                      color: isActive || isCompleted
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(
                            Icons.check,
                            size: 18,
                            color: Theme.of(context).colorScheme.onPrimary,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                  ),
                ),
                // Линия к следующему шагу
                if (index < _stepTitles.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: isCompleted
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Название шага
            Text(
              _stepTitles[index],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    CreateStoreController controller,
    bool isFirstStep,
    bool isLastStep,
    bool isLoading,
    bool isReady,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Кнопка "Назад"
          if (!isFirstStep)
            Expanded(
              child: SmoothButton(
                onPressed: isLoading ? null : controller.previousStep,
                label: 'Назад',
                type: SmoothButtonType.outlined,
                size: SmoothButtonSize.medium,
                icon: const Icon(Icons.arrow_back),
              ),
            ),
          if (!isFirstStep) const SizedBox(width: 16),

          // Кнопка "Далее" или "Создать"
          Expanded(
            flex: isFirstStep ? 1 : 1,
            child: SmoothButton(
              isFullWidth: true,
              onPressed: () async {
                if (isLastStep) {
                  // Последний шаг - создаем хранилище
                  if (isReady && (_formKey.currentState?.validate() ?? false)) {
                    await controller.createStore();
                  }
                } else {
                  // Переходим к следующему шагу
                  if (controller.isCurrentStepValid()) {
                    controller.nextStep();
                  }
                }
              },
              loading: isLoading,
              label: isLastStep ? 'Создать хранилище' : 'Далее',
              type: SmoothButtonType.filled,
              size: SmoothButtonSize.medium,
              icon: Icon(isLastStep ? Icons.check : Icons.arrow_forward),
              iconPosition: SmoothButtonIconPosition.end,
            ),
          ),
        ],
      ),
    );
  }
}
