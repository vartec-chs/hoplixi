import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/shared/widgets/button.dart';
import 'package:hoplixi/shared/widgets/text_field.dart';
import 'package:hoplixi/shared/widgets/password_field.dart';
import 'package:hoplixi/app/constants/main_constants.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/before_opening/open_store/open_store_control.dart';
import 'package:hoplixi/features/password_manager/before_opening/open_store/widgets/database_files_list.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';
import 'package:hoplixi/app/router/routes_path.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/hoplixi_store/models/db_state.dart';

class OpenStoreScreen extends ConsumerStatefulWidget {
  const OpenStoreScreen({super.key});

  @override
  ConsumerState<OpenStoreScreen> createState() => _OpenStoreScreenState();
}

class _OpenStoreScreenState extends ConsumerState<OpenStoreScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _pathController;
  late final TextEditingController _passwordController;

  bool _showAllFiles = false;

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    // Очищаем все контроллеры
    _pathController.clear();
    _passwordController.clear();

    // Освобождаем ресурсы
    _pathController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(openStoreControllerProvider);
    final controller = ref.read(openStoreControllerProvider.notifier);
    final isReady = ref.watch(openStoreReadyProvider);

    // Слушаем изменения состояния базы данных
    ref.listen<AsyncValue<DatabaseState>>(hoplixiStoreProvider, (
      previous,
      next,
    ) {
      if (next.isLoading) {
        // Показываем индикатор загрузки
        controller.setLoading(true);
      } else {
        controller.setLoading(false);
      }
      if (next.value?.isOpen == true &&
          previous?.value?.status != next.value?.status) {
        // База данных успешно открыта, очищаем данные и показываем уведомление
        controller.clearAllData();

        // Очищаем текстовые контроллеры
        _pathController.clear();
        _passwordController.clear();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ToastHelper.success(
            title: 'Успех',
            description: 'Хранилище успешно открыто!',
          );
          context.go(AppRoutes.dashboard);
        });

        // Future.microtask(() {
        //   if (mounted) {
        //     ToastHelper.success(
        //       title: 'Успех',
        //       description: 'Хранилище успешно открыто!',
        //     );
        //     // Переходим на главный экран после успешного открытия
        //     context.go(AppRoutes.dashboard);
        //   }
        // });
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
          ref.read(openStoreControllerProvider.notifier).clearAllData();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Открыть хранилище'),
          surfaceTintColor: Colors.transparent,
          leading: BackButton(
            onPressed: () {
              // Очищаем данные перед уходом с экрана
              ref.read(openStoreControllerProvider.notifier).clearAllData();
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
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        spacing: 12,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Описание
                          Card(
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Открытие хранилища',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Выберите файл хранилища (.${MainConstants.dbExtension}) и введите мастер-пароль для его открытия.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Найденные файлы БД
                          Consumer(
                            builder: (context, ref, child) {
                              final databaseFilesAsync = ref.watch(
                                databaseFilesProvider,
                              );

                              return databaseFilesAsync.when(
                                data: (result) {
                                  if (result.files.isNotEmpty) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        DatabaseFilesList(
                                          files: result.files,
                                          selectedFile:
                                              result.files
                                                  .where(
                                                    (f) =>
                                                        f.path ==
                                                        formState.databasePath,
                                                  )
                                                  .isEmpty
                                              ? null
                                              : result.files
                                                    .where(
                                                      (f) =>
                                                          f.path ==
                                                          formState
                                                              .databasePath,
                                                    )
                                                    .first,
                                          onFileSelected: (file) {
                                            controller.selectDatabaseFromInfo(
                                              file,
                                            );

                                            _pathController.text = file.path;
                                            _passwordController.text = '';
                                            ToastHelper.info(
                                              title: 'Файл выбран',
                                              description:
                                                  'Выбран файл: ${file.path}',
                                            );
                                          },
                                          showAllFiles: _showAllFiles,
                                          onToggleShowAll: () {
                                            setState(() {
                                              _showAllFiles = !_showAllFiles;
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                                loading: () => Card(
                                  elevation: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Поиск файлов хранилищ...',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                error: (error, stack) =>
                                    const SizedBox.shrink(),
                              );
                            },
                          ),

                          // Путь к файлу хранилища
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Выбрать файл вручную',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _pathController,
                                      readOnly: true,
                                      onChanged: controller.updateDatabasePath,
                                      decoration:
                                          primaryInputDecoration(
                                            context,
                                            labelText: 'Путь к файлу хранилища',
                                            hintText:
                                                'Выберите файл хранилища...',
                                            errorText: formState
                                                .fieldErrors['databasePath'],
                                            filled: true,
                                          ).copyWith(
                                            prefixIcon: const Icon(
                                              Icons.folder,
                                            ),
                                          ),
                                      validator: (value) =>
                                          formState.fieldErrors['databasePath'],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SmoothButton(
                                    onPressed: () async {
                                      await controller.selectDatabaseFile();
                                      // Синхронизируем контроллер с состоянием
                                      final newFormState = ref.read(
                                        openStoreControllerProvider,
                                      );
                                      if (newFormState
                                          .databasePath
                                          .isNotEmpty) {
                                        _pathController.text =
                                            newFormState.databasePath;
                                      }
                                    },
                                    type: SmoothButtonType.outlined,
                                    size: SmoothButtonSize.medium,
                                    label: 'Выбрать',
                                    icon: const Icon(Icons.file_open),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Мастер пароль
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Мастер-пароль',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              CustomPasswordField(
                                label: 'Мастер-пароль',
                                controller: _passwordController,
                                onChanged: controller.updateMasterPassword,
                                errorText:
                                    formState.fieldErrors['masterPassword'],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Введите мастер-пароль, который использовался при создании хранилища.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                              ),
                            ],
                          ),

                          // Переключатель сохранения пароля с предупреждением
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SwitchListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    value: formState.saveMasterPassword,
                                    onChanged:
                                        controller.toggleSaveMasterPassword,
                                    title: const Text(
                                      'Сохранить мастер-пароль',
                                    ),
                                    subtitle: const Text(
                                      'Автоматически открывать хранилище без ввода пароля',
                                    ),
                                    contentPadding: EdgeInsets.all(8),
                                  ),

                                  if (formState.saveMasterPassword) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        // color: Colors.red.withValues(
                                        //   alpha: 0.05,
                                        // ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.red.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.warning_amber,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'ВНИМАНИЕ: РИСК БЕЗОПАСНОСТИ',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.error,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Сохранение мастер-пароля крайне рискованно! Включайте эту опцию только если:\n'
                                            '• Вы уверены в безопасности своего окружения\n'
                                            '• На устройстве нет вирусов и вредоносного ПО\n'
                                            '• Устройство защищено надежным паролем/биометрией\n'
                                            '• Никто другой не имеет доступа к устройству\n\n'
                                            'При компрометации устройства злоумышленники получат доступ ко всем вашим паролям!',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.error,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Информация о выбранном файле
                          if (formState.databasePath.isNotEmpty) ...[
                            const Divider(),
                            Card(
                              elevation: 0,
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainer,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.storage,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Выбранное хранилище',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      formState.databasePath,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Кнопка открытия
                  SmoothButton(
                    isFullWidth: true,
                    onPressed: isReady
                        ? () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              await controller.openStore();
                            }
                          }
                        : null,
                    loading: formState.isLoading,
                    label: "Открыть хранилище",
                    type: SmoothButtonType.filled,
                    size: SmoothButtonSize.medium,
                    icon: const Icon(Icons.lock_open),
                  ),
                ],
              ),
            ),
          ),
        ), // Закрываем Scaffold
      ),
    ); // Закрываем PopScope
  }
}
