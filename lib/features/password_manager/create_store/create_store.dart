import 'package:flutter/material.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/common/text_field.dart';

import 'package:hoplixi/router/routes_path.dart';
import 'package:go_router/go_router.dart';

class CreateStoreScreen extends StatelessWidget {
  const CreateStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать хранилище'),
        surfaceTintColor: Colors.transparent,
        leading: BackButton(
          onPressed: () {
            context.go(AppRoutes.home);
          },
        ),
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 8,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    spacing: 8,
                    children: [
                      TextFormField(
                        decoration:
                            primaryInputDecoration(
                              context,
                              labelText: 'Название хранилища',
                              filled: true,
                            ).copyWith(
                              prefixIcon: IconButton(
                                icon: const Icon(Icons.title),
                                onPressed: () {},
                              ),
                            ),
                      ),
                      TextFormField(
                        decoration:
                            primaryInputDecoration(
                              context,
                              labelText: 'Описание хранилища',

                              filled: true,
                            ).copyWith(
                              prefixIcon: IconButton(
                                icon: const Icon(Icons.subtitles),
                                onPressed: () {},
                              ),
                            ),
                        minLines: 2,
                        maxLines: 4,
                      ),
                      PasswordField(label: 'Мастер пароль'),
                      PasswordField(label: 'Подтвердите мастер пароль'),
                      Divider(
                        color: Theme.of(context).colorScheme.outline,
                        radius: BorderRadius.all(Radius.circular(12)),
                      ),
                      SegmentedButton(
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
                        selected: <bool>{true},
                        onSelectionChanged: (Set<bool> newSelection) {},
                      ),
                      TextFormField(
                        decoration:
                            primaryInputDecoration(
                              context,
                              labelText: 'Итоговый путь',
                              helperText:
                                  'Итоговый путь где будут храниться файл паролей',
                              filled: true,
                            ).copyWith(
                              prefixIcon: IconButton(
                                icon: const Icon(Icons.folder_open),
                                onPressed: () {},
                              ),
                            ),
                        minLines: 1,
                        maxLines: 3,
                        readOnly: true,
                        initialValue:
                            'C:\\Users\\User\\Desktop\\password_manager',
                        enabled: false,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                child: SmoothButton(
                  onPressed: () {},
                  // loading: true,
                  label: "Создать",
                  type: SmoothButtonType.filled,
                  size: SmoothButtonSize.medium,
                  icon: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
