import 'package:flutter/material.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/common/text_field.dart';
import 'package:hoplixi/core/theme/constants.dart';

class CreateStoreScreen extends StatelessWidget {
  const CreateStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать хранилище'),
        surfaceTintColor: Colors.transparent,
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
                        decoration: primaryInputDecoration(
                          context,
                          labelText: 'Text Field',
                          filled: true,
                          hintText: 'Введите текст',
                        ),

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите текст';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        decoration: primaryInputDecoration(
                          context,
                          labelText: 'Text Field',
                          filled: true,
                        ),
                      ),
                      ...List.generate(10, (index) {
                        return TextFormField(
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Text Field ${index + 1}',
                            filled: true,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: SmoothButton(
                    onPressed: () {},
                    loading: true,
                    label: "Создать",
                    type: SmoothButtonType.filled,
                    size: SmoothButtonSize.medium,
                    icon: const Icon(Icons.add),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
