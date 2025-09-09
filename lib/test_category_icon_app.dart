import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/category/category_manager_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/icons/icon_manager_screen.dart';

/// Тестовое приложение для демонстрации работы с категориями и иконками
class CategoryIconTestApp extends StatelessWidget {
  const CategoryIconTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Category & Icon Manager Demo',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const MainDemoScreen(),
      ),
    );
  }
}

class MainDemoScreen extends StatelessWidget {
  const MainDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category & Icon Manager Demo'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.category,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Управление категориями и иконками',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Демонстрация функциональности для создания, редактирования и управления категориями и иконками',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 280,
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CategoryManagerScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.category),
                      label: const Text('Управление категориями'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const IconManagerScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.image),
                      label: const Text('Управление иконками'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Возможности',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _FeatureItem(
                        icon: Icons.add_circle,
                        text: 'Создание категорий разных типов',
                      ),
                      const _FeatureItem(
                        icon: Icons.edit,
                        text: 'Редактирование категорий',
                      ),
                      const _FeatureItem(
                        icon: Icons.file_upload,
                        text: 'Загрузка иконок (SVG, PNG, JPG, GIF)',
                      ),
                      const _FeatureItem(
                        icon: Icons.phone_android,
                        text: 'Адаптивный интерфейс (модалки/bottom sheets)',
                      ),
                      const _FeatureItem(
                        icon: Icons.search,
                        text: 'Поиск и фильтрация',
                      ),
                      const _FeatureItem(
                        icon: Icons.analytics,
                        text: 'Статистика и аналитика',
                      ),
                    ],
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

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
