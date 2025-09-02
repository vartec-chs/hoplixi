import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/common/text_field.dart';
import 'package:hoplixi/common/password_field.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/create_store/create_store_control.dart';
import 'package:hoplixi/router/routes_path.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/hoplixi_store/state.dart';

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

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(createStoreControllerProvider);
    final controller = ref.read(createStoreControllerProvider.notifier);
    final isReady = ref.watch(createStoreReadyProvider);

    // Слушаем изменения состояния базы данных
    ref.listen<DatabaseState>(createStoreDatabaseStateProvider, (
      previous,
      next,
    ) {
      if (next.isOpen && previous?.status != next.status) {
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
          context.go(AppRoutes.home);
        });
        // Toast.success('Хранилище успешно создано!');
      }
    });

    // Показываем ошибки
    if (formState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text(formState.errorMessage!),
        //     backgroundColor: Colors.red,
        //   ),
        // );
        // Toast.error(formState.errorMessage!);
        ToastHelper.error(
          // context: context,
          title: 'Ошибка',
          description: formState.errorMessage!,
        );
        // Toast.error(formState.errorMessage!);
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
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: Column(
                spacing: 8,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        spacing: 8,
                        children: [
                          // Название хранилища
                          TextFormField(
                            controller: _nameController,
                            onChanged: controller.updateStoreName,
                            decoration:
                                primaryInputDecoration(
                                  context,
                                  labelText: 'Название хранилища',
                                  filled: true,
                                  errorText: formState.fieldErrors['storeName'],
                                ).copyWith(
                                  prefixIcon: IconButton(
                                    icon: const Icon(Icons.title),
                                    onPressed: () {},
                                  ),
                                ),
                            validator: (value) =>
                                formState.fieldErrors['storeName'],
                          ),

                          // Описание хранилища
                          TextFormField(
                            controller: _descriptionController,
                            onChanged: controller.updateStoreDescription,
                            decoration:
                                primaryInputDecoration(
                                  context,
                                  labelText: 'Описание хранилища',
                                  filled: true,
                                  errorText:
                                      formState.fieldErrors['storeDescription'],
                                ).copyWith(
                                  prefixIcon: IconButton(
                                    icon: const Icon(Icons.subtitles),
                                    onPressed: () {},
                                  ),
                                ),
                            minLines: 2,
                            maxLines: 4,
                            validator: (value) =>
                                formState.fieldErrors['storeDescription'],
                          ),

                          // Мастер пароль
                          CustomPasswordField(
                            label: 'Мастер пароль',
                            controller: _masterPasswordController,
                            onChanged: controller.updateMasterPassword,
                            errorText: formState.fieldErrors['masterPassword'],
                          ),

                          // Подтверждение пароля
                          CustomPasswordField(
                            label: 'Подтвердите мастер пароль',
                            controller: _confirmPasswordController,
                            onChanged: controller.updateConfirmPassword,
                            errorText: formState.fieldErrors['confirmPassword'],
                          ),

                          Divider(
                            color: Theme.of(context).colorScheme.outline,
                            radius: BorderRadius.all(Radius.circular(12)),
                          ),

                          // Выбор типа пути
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: true,
                                label: Text('Предустановленный путь'),
                              ),
                              ButtonSegment(
                                value: false,
                                label: Text('Пользовательский путь'),
                              ),
                            ],
                            selected: <bool>{formState.isDefaultPath},
                            onSelectionChanged: (Set<bool> newSelection) {
                              controller.togglePathType(newSelection.first);
                            },
                          ),

                          // Итоговый путь
                          TextFormField(
                            decoration:
                                primaryInputDecoration(
                                  context,
                                  labelText: 'Итоговый путь',
                                  helperText:
                                      'Итоговый путь где будет сохранен файл хранилища',
                                  filled: true,
                                ).copyWith(
                                  prefixIcon: IconButton(
                                    icon: const Icon(Icons.folder_open),
                                    onPressed: formState.isDefaultPath
                                        ? null
                                        : () {
                                            controller.selectCustomPath();
                                          },
                                  ),
                                ),
                            minLines: 1,
                            maxLines: 3,
                            readOnly: true,
                            initialValue: formState.finalPath,
                            key: ValueKey(
                              formState.finalPath,
                            ), // Принудительное обновление
                            enabled: false,
                          ),

                          if (!formState.isDefaultPath)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: formState.isLoading
                                    ? null
                                    : controller.selectCustomPath,
                                icon: const Icon(Icons.folder_open),
                                label: const Text('Выбрать путь'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Кнопка создания
                  SmoothButton(
                    isFullWidth: true,
                    onPressed: isReady
                        ? () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              await controller.createStore();
                            }
                          }
                        : null,
                    loading: formState.isLoading,
                    label: "Создать",
                    type: SmoothButtonType.filled,
                    size: SmoothButtonSize.medium,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
