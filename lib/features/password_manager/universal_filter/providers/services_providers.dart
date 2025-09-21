import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/services/categories_service.dart';
import 'package:hoplixi/hoplixi_store/services/tags_service.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store_providers.dart';

/// Провайдер для сервиса категорий
final categoriesServiceProvider = Provider<CategoriesService>((ref) {
  final dbNotifier = ref.watch(hoplixiStoreProvider.notifier);
  final storeInstance = dbNotifier.currentDatabase;
  return CategoriesService(storeInstance.categoriesDao);
});

/// Провайдер для сервиса тегов
final tagsServiceProvider = Provider<TagsService>((ref) {
  final dbNotifier = ref.watch(hoplixiStoreProvider.notifier);
  final storeInstance = dbNotifier.currentDatabase;
  return TagsService(storeInstance.tagsDao);
});
