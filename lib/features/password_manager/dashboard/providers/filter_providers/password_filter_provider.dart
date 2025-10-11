import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/models/filter_models/password_filter.dart';
import 'package:hoplixi/hoplixi_store/models/filter_models/base_filter.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'base_filter_provider.dart';

/// Провайдер для управления фильтром паролей
final passwordFilterProvider =
    NotifierProvider<PasswordFilterNotifier, PasswordFilter>(
      () => PasswordFilterNotifier(),
    );

class PasswordFilterNotifier extends Notifier<PasswordFilter> {
  @override
  PasswordFilter build() {
    logDebug('PasswordFilterNotifier: Инициализация фильтра паролей');

    // Подписываемся на изменения базового фильтра
    ref.listen(baseFilterProvider, (previous, next) {
      logDebug('PasswordFilterNotifier: Обновление базового фильтра');
      state = state.copyWith(base: next);
    });

    return PasswordFilter(base: ref.read(baseFilterProvider));
  }

  /// Обновляет название пароля
  void updateName(String? name) {
    final normalizedName = name?.trim();
    logDebug('PasswordFilterNotifier: Обновление названия: $normalizedName');
    state = state.copyWith(
      name: normalizedName?.isEmpty == true ? null : normalizedName,
    );
  }

  /// Обновляет URL
  void updateUrl(String? url) {
    final normalizedUrl = url?.trim();
    logDebug('PasswordFilterNotifier: Обновление URL: $normalizedUrl');
    state = state.copyWith(
      url: normalizedUrl?.isEmpty == true ? null : normalizedUrl,
    );
  }

  /// Обновляет имя пользователя
  void updateUsername(String? username) {
    final normalizedUsername = username?.trim();
    logDebug(
      'PasswordFilterNotifier: Обновление имени пользователя: $normalizedUsername',
    );
    state = state.copyWith(
      username: normalizedUsername?.isEmpty == true ? null : normalizedUsername,
    );
  }

  /// Обновляет фильтр наличия URL
  void updateHasUrl(bool? hasUrl) {
    logDebug('PasswordFilterNotifier: Обновление фильтра наличия URL: $hasUrl');
    state = state.copyWith(hasUrl: hasUrl);
  }

  /// Обновляет фильтр наличия имени пользователя
  void updateHasUsername(bool? hasUsername) {
    logDebug(
      'PasswordFilterNotifier: Обновление фильтра наличия имени пользователя: $hasUsername',
    );
    state = state.copyWith(hasUsername: hasUsername);
  }

  /// Обновляет фильтр наличия TOTP
  void updateHasTotp(bool? hasTotp) {
    logDebug(
      'PasswordFilterNotifier: Обновление фильтра наличия TOTP: $hasTotp',
    );
    state = state.copyWith(hasTotp: hasTotp);
  }

  /// Обновляет фильтр скомпрометированных паролей
  void updateIsCompromised(bool? isCompromised) {
    logDebug(
      'PasswordFilterNotifier: Обновление фильтра скомпрометированных: $isCompromised',
    );
    state = state.copyWith(isCompromised: isCompromised);
  }

  /// Обновляет фильтр истекших паролей
  void updateIsExpired(bool? isExpired) {
    logDebug('PasswordFilterNotifier: Обновление фильтра истекших: $isExpired');
    state = state.copyWith(isExpired: isExpired);
  }

  /// Обновляет фильтр часто используемых паролей
  void updateIsFrequent(bool? isFrequent) {
    logDebug(
      'PasswordFilterNotifier: Обновление фильтра часто используемых: $isFrequent',
    );
    state = state.copyWith(isFrequent: isFrequent);
  }

  /// Обновляет поле сортировки
  void updateSortField(PasswordSortField? sortField) {
    logDebug('PasswordFilterNotifier: Обновление поля сортировки: $sortField');
    state = state.copyWith(sortField: sortField);
  }

  /// Сбрасывает фильтр к начальному состоянию
  void reset() {
    logDebug('PasswordFilterNotifier: Сброс фильтра паролей');
    state = PasswordFilter(base: ref.read(baseFilterProvider));
  }

  /// Применяет новый фильтр паролей
  void applyFilter(PasswordFilter filter) {
    logDebug('PasswordFilterNotifier: Применение нового фильтра паролей');
    state = filter;
  }

  /// Создает новый фильтр с указанными параметрами
  void createFilter({
    BaseFilter? base,
    String? name,
    String? url,
    String? username,
    bool? hasUrl,
    bool? hasUsername,
    bool? hasTotp,
    bool? isCompromised,
    bool? isExpired,
    bool? isFrequent,
    PasswordSortField? sortField,
  }) {
    logDebug('PasswordFilterNotifier: Создание нового фильтра');
    final newFilter = PasswordFilter.create(
      base: base ?? ref.read(baseFilterProvider),
      name: name,
      url: url,
      username: username,
      hasUrl: hasUrl,
      hasUsername: hasUsername,
      hasTotp: hasTotp,
      isCompromised: isCompromised,
      isExpired: isExpired,
      isFrequent: isFrequent,
      sortField: sortField,
    );
    state = newFilter;
  }

  /// Проверяет, есть ли активные ограничения
  bool get hasActiveConstraints => state.hasActiveConstraints;

  /// Проверяет валидность фильтра
  bool get isValid => state.isValidUsedCountRange && state.isValidStrengthRange;

  /// Получает базовый фильтр
  BaseFilter get baseFilter => state.base;

  /// Обновляет базовый фильтр
  void updateBaseFilter(BaseFilter baseFilter) {
    logDebug('PasswordFilterNotifier: Обновление базового фильтра');
    state = state.copyWith(base: baseFilter);
  }
}
