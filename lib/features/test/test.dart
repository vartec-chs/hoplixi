import 'package:flutter/material.dart';
import 'package:hoplixi/core/constants/responsive_constants.dart';
import 'package:hoplixi/features/test/widgets/test_scaffold_messenger.dart';
import 'package:hoplixi/router/router_provider.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Screen'),
        leading: BackButton(
          onPressed: () {
            navigateBack(context);
          },
        ),
      ),
      body: SafeArea(
        child: Container(
          padding: screenPadding,
          child: SingleChildScrollView(
            child: Column(
              children: [
                FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const TestScaffoldMessengerScreen(),
                      ),
                    );
                  },
                  child: const Text('Открыть полное демо'),
                ),
                FilledButton(onPressed: () {}, child: const Text('Кнопка 2')),
                FilledButton(onPressed: () {}, child: const Text('Кнопка 3')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
