import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/models/filter/otp_filter.dart';
import 'package:hoplixi/hoplixi_store/models/filter/base_filter.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'base_filter_provider.dart';

/// Провайдер для управления фильтром OTP
final otpFilterProvider = NotifierProvider<OtpFilterNotifier, OtpFilter>(
  () => OtpFilterNotifier(),
);

class OtpFilterNotifier extends Notifier<OtpFilter> {
  @override
  OtpFilter build() {
    logDebug('OtpFilterNotifier: Инициализация фильтра OTP');

    // Подписываемся на изменения базового фильтра
    ref.listen(baseFilterProvider, (previous, next) {
      logDebug('OtpFilterNotifier: Обновление базового фильтра');
      state = state.copyWith(base: next);
    });

    return OtpFilter(base: ref.read(baseFilterProvider));
  }

  /// Обновляет тип OTP (TOTP/HOTP)
  void updateType(OtpType? type) {
    logDebug('OtpFilterNotifier: Обновление типа OTP: $type');
    state = state.copyWith(type: type);
  }

  /// Обновляет издателя (issuer)
  void updateIssuer(String? issuer) {
    final normalizedIssuer = issuer?.trim();
    logDebug('OtpFilterNotifier: Обновление издателя: $normalizedIssuer');
    state = state.copyWith(
      issuer: normalizedIssuer?.isEmpty == true ? null : normalizedIssuer,
    );
  }

  /// Обновляет имя аккаунта
  void updateAccountName(String? accountName) {
    final normalizedAccountName = accountName?.trim();
    logDebug(
      'OtpFilterNotifier: Обновление имени аккаунта: $normalizedAccountName',
    );
    state = state.copyWith(
      accountName: normalizedAccountName?.isEmpty == true
          ? null
          : normalizedAccountName,
    );
  }

  /// Обновляет список алгоритмов
  void updateAlgorithms(List<String>? algorithms) {
    final normalizedAlgorithms = algorithms
        ?.where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim().toUpperCase())
        .toSet()
        .toList();

    logDebug('OtpFilterNotifier: Обновление алгоритмов: $normalizedAlgorithms');
    state = state.copyWith(
      algorithms: normalizedAlgorithms?.isEmpty == true
          ? null
          : normalizedAlgorithms,
    );
  }

  /// Добавляет алгоритм к фильтру
  void addAlgorithm(String algorithm) {
    final normalizedAlgorithm = algorithm.trim().toUpperCase();
    if (normalizedAlgorithm.isEmpty) return;

    final currentAlgorithms = List<String>.from(state.algorithms ?? []);
    if (!currentAlgorithms.contains(normalizedAlgorithm)) {
      currentAlgorithms.add(normalizedAlgorithm);
      logDebug('OtpFilterNotifier: Добавлен алгоритм: $normalizedAlgorithm');
      state = state.copyWith(algorithms: currentAlgorithms);
    }
  }

  /// Удаляет алгоритм из фильтра
  void removeAlgorithm(String algorithm) {
    final normalizedAlgorithm = algorithm.trim().toUpperCase();
    final currentAlgorithms = List<String>.from(state.algorithms ?? []);

    if (currentAlgorithms.remove(normalizedAlgorithm)) {
      logDebug('OtpFilterNotifier: Удален алгоритм: $normalizedAlgorithm');
      state = state.copyWith(
        algorithms: currentAlgorithms.isEmpty ? null : currentAlgorithms,
      );
    }
  }

  /// Обновляет количество цифр
  void updateDigits(int? digits) {
    logDebug('OtpFilterNotifier: Обновление количества цифр: $digits');

    // Валидация: только 6 или 8 цифр допустимы
    if (digits != null && digits != 6 && digits != 8) {
      logDebug(
        'OtpFilterNotifier: Недопустимое количество цифр: $digits. Разрешены только 6 или 8',
      );
      return;
    }

    state = state.copyWith(digits: digits);
  }

  /// Обновляет период для TOTP
  void updatePeriod(int? period) {
    logDebug('OtpFilterNotifier: Обновление периода: $period');

    // Валидация: период должен быть от 1 до 300 секунд
    if (period != null && (period <= 0 || period > 300)) {
      logDebug(
        'OtpFilterNotifier: Недопустимый период: $period. Должен быть от 1 до 300 секунд',
      );
      return;
    }

    state = state.copyWith(period: period);
  }

  /// Обновляет фильтр наличия связи с паролем
  void updateHasPasswordLink(bool? hasPasswordLink) {
    logDebug(
      'OtpFilterNotifier: Обновление фильтра связи с паролем: $hasPasswordLink',
    );
    state = state.copyWith(hasPasswordLink: hasPasswordLink);
  }

  /// Обновляет поле сортировки
  void updateSortField(OtpSortField? sortField) {
    logDebug('OtpFilterNotifier: Обновление поля сортировки: $sortField');
    state = state.copyWith(sortField: sortField);
  }

  /// Сбрасывает фильтр к начальному состоянию
  void reset() {
    logDebug('OtpFilterNotifier: Сброс фильтра OTP');
    state = OtpFilter(base: ref.read(baseFilterProvider));
  }

  /// Применяет новый фильтр OTP
  void applyFilter(OtpFilter filter) {
    logDebug('OtpFilterNotifier: Применение нового фильтра OTP');
    state = filter;
  }

  /// Создает новый фильтр с указанными параметрами
  void createFilter({
    BaseFilter? base,
    OtpType? type,
    String? issuer,
    String? accountName,
    List<String>? algorithms,
    int? digits,
    int? period,
    bool? hasPasswordLink,
    OtpSortField? sortField,
  }) {
    logDebug('OtpFilterNotifier: Создание нового фильтра');
    final newFilter = OtpFilter.create(
      base: base ?? ref.read(baseFilterProvider),
      type: type,
      issuer: issuer,
      accountName: accountName,
      algorithms: algorithms,
      digits: digits,
      period: period,
      hasPasswordLink: hasPasswordLink,
      sortField: sortField,
    );
    state = newFilter;
  }

  /// Проверяет, есть ли активные ограничения
  bool get hasActiveConstraints => state.hasActiveConstraints;

  /// Проверяет валидность периода для TOTP
  bool get isValidPeriod => state.isValidPeriod;

  /// Проверяет валидность количества цифр
  bool get isValidDigits => state.isValidDigits;

  /// Проверяет общую валидность фильтра
  bool get isValid => isValidPeriod && isValidDigits;

  /// Получает базовый фильтр
  BaseFilter get baseFilter => state.base;

  /// Обновляет базовый фильтр
  void updateBaseFilter(BaseFilter baseFilter) {
    logDebug('OtpFilterNotifier: Обновление базового фильтра');
    state = state.copyWith(base: baseFilter);
  }

  /// Получает список поддерживаемых алгоритмов
  static List<String> get supportedAlgorithms => ['SHA1', 'SHA256', 'SHA512'];

  /// Получает список поддерживаемых количеств цифр
  static List<int> get supportedDigits => [6, 8];

  /// Проверяет, поддерживается ли алгоритм
  static bool isSupportedAlgorithm(String algorithm) {
    return supportedAlgorithms.contains(algorithm.toUpperCase());
  }

  /// Проверяет, поддерживается ли количество цифр
  static bool isSupportedDigits(int digits) {
    return supportedDigits.contains(digits);
  }
}
