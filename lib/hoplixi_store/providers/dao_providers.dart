library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/dao/filters_dao/otp_filter_dao.dart';
import 'package:hoplixi/hoplixi_store/dao/index.dart';
import 'hoplixi_store_providers.dart';

// =============================================================================
// DAO ПРОВАЙДЕРЫ
// =============================================================================

/// Провайдер для CategoriesDao
final categoriesDaoProvider = Provider<CategoriesDao>((ref) {
  final db = ref.watch(hoplixiStoreProvider.notifier);

  return CategoriesDao(db.currentDatabase);
});

/// Провайдер для IconsDao
final iconsDaoProvider = Provider<IconsDao>((ref) {
  final db = ref.watch(hoplixiStoreProvider.notifier);

  return IconsDao(db.currentDatabase);
});

final tagsDaoProvider = Provider<TagsDao>((ref) {
  final db = ref.watch(hoplixiStoreProvider.notifier);

  return TagsDao(db.currentDatabase);
});

final passwordsDaoProvider = Provider<PasswordsDao>((ref) {
  final db = ref.watch(hoplixiStoreProvider.notifier);

  return PasswordsDao(db.currentDatabase);
});

final passwordsHistoryDaoProvider = Provider.autoDispose<PasswordHistoriesDao>((
  ref,
) {
  final db = ref.watch(hoplixiStoreProvider.notifier);

  return PasswordHistoriesDao(db.currentDatabase);
});

// PasswordTagsDao
final passwordTagsDaoProvider = Provider<PasswordTagsDao>((ref) {
  final db = ref.watch(hoplixiStoreProvider.notifier);

  return PasswordTagsDao(db.currentDatabase);
});

final passwordFilterDaoProvider = Provider<PasswordFilterDao>((ref) {
  final db = ref.watch(hoplixiStoreProvider.notifier);

  ref.onDispose(() {
    logInfo(
      'Освобождение ресурсов PasswordFilterDao',
      tag: 'ServicesProviders',
    );
  });

  return PasswordFilterDao(db.currentDatabase);
});

final otpsDaoProvider = Provider.autoDispose<OtpsDao>((ref) {
  final db = ref.watch(hoplixiStoreProvider.notifier);

  return OtpsDao(db.currentDatabase);
});

final otpFilterDaoProvider = Provider.autoDispose<OtpFilterDao>((ref) {
  final db = ref.watch(hoplixiStoreProvider.notifier);

  return OtpFilterDao(db.currentDatabase);
});
