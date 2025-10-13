import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/shared/widgets/button.dart';

class ErrorScreen extends StatelessWidget {
  final String errorMessage;

  const ErrorScreen({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ошибка')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Упс! Произошла ошибка:', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Container(
                  constraints: BoxConstraints(maxWidth: 400),
                  child: Text(
                    errorMessage,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      wordSpacing: 1.2,
                      // overflow: TextOverflow.ellipsis,
                    ),

                    softWrap: true,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 16),
                SmoothButton(
                  type: SmoothButtonType.text,
                  label: 'Копировать',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: errorMessage));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Текст ошибки скопирован в буфер'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
