import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'password_form.dart';

/// Пример использования экрана формы пароля
class PasswordFormExample extends ConsumerWidget {
  const PasswordFormExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пример формы пароля')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Кнопка создания нового пароля
            ElevatedButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => const PasswordFormScreen(),
                      ),
                    )
                    .then((result) {
                      if (result == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Пароль успешно создан!'),
                          ),
                        );
                      }
                    });
              },
              child: const Text('Создать новый пароль'),
            ),

            const SizedBox(height: 16),

            // Кнопка редактирования существующего пароля
            // (в реальном приложении ID пароля будет получен из списка)
            ElevatedButton(
              onPressed: () {
                // Пример с фиктивным ID для демонстрации
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => const PasswordFormScreen(
                          passwordId: 'example-password-id',
                        ),
                      ),
                    )
                    .then((result) {
                      if (result == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Пароль успешно обновлен!'),
                          ),
                        );
                      }
                    });
              },
              child: const Text('Редактировать пароль (пример)'),
            ),

            const SizedBox(height: 32),

            // Информация о функциях безопасности
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Функции безопасности:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSecurityFeature(
                      '🔒',
                      'Автоматическая очистка полей при закрытии',
                    ),
                    _buildSecurityFeature(
                      '🔐',
                      'Безопасная очистка памяти от чувствительных данных',
                    ),
                    _buildSecurityFeature(
                      '📱',
                      'Очистка при сворачивании приложения',
                    ),
                    _buildSecurityFeature(
                      '✅',
                      'Валидация полей в реальном времени',
                    ),
                    _buildSecurityFeature(
                      '🎲',
                      'Встроенный генератор сложных паролей',
                    ),
                    _buildSecurityFeature(
                      '👁️',
                      'Переключение видимости пароля',
                    ),
                    _buildSecurityFeature('🏷️', 'Поддержка категорий и тегов'),
                    _buildSecurityFeature(
                      '⭐',
                      'Возможность отметить как избранное',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityFeature(String icon, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(description, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
