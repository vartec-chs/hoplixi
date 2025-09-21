import 'package:freezed_annotation/freezed_annotation.dart';
import 'base_filter.dart';

part 'otp_filter.freezed.dart';
part 'otp_filter.g.dart';

enum OtpType { totp, hotp }

enum OtpSortField { issuer, accountName, createdAt, modifiedAt, lastAccessed }

@freezed
abstract class OtpFilter with _$OtpFilter {
  const factory OtpFilter({
    required BaseFilter base,
    OtpType? type, // фильтр по типу TOTP/HOTP
    String? issuer, // фильтр по issuer (например, "Google", "GitHub")
    String? accountName, // фильтр по имени аккаунта
    List<String>? algorithms, // фильтр по алгоритму (SHA1, SHA256, SHA512)
    int? digits, // фильтр по количеству цифр (6, 8)
    int? period, // фильтр по периоду для TOTP
    bool? hasPasswordLink, // есть ли связь с паролем
    OtpSortField? sortField,
  }) = _OtpFilter;

  factory OtpFilter.create({
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
    final normalizedIssuer = issuer?.trim();
    final normalizedAccountName = accountName?.trim();
    final normalizedAlgorithms = algorithms
        ?.where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim().toUpperCase())
        .toSet()
        .toList();

    return OtpFilter(
      base: base ?? const BaseFilter(),
      type: type,
      issuer: normalizedIssuer?.isEmpty == true ? null : normalizedIssuer,
      accountName: normalizedAccountName?.isEmpty == true
          ? null
          : normalizedAccountName,
      algorithms: normalizedAlgorithms?.isEmpty == true
          ? null
          : normalizedAlgorithms,
      digits: digits,
      period: period,
      hasPasswordLink: hasPasswordLink,
      sortField: sortField,
      
    );
  }

  factory OtpFilter.fromJson(Map<String, dynamic> json) =>
      _$OtpFilterFromJson(json);
}

extension OtpFilterHelpers on OtpFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (type != null) return true;
    if (issuer != null) return true;
    if (accountName != null) return true;
    if (algorithms != null && algorithms!.isNotEmpty) return true;
    if (digits != null) return true;
    if (period != null) return true;
    if (hasPasswordLink != null) return true;
    return false;
  }

  /// Проверка валидности периода для TOTP
  bool get isValidPeriod {
    if (type == OtpType.totp && period != null) {
      return period! > 0 && period! <= 300; // от 1 секунды до 5 минут
    }
    return true;
  }

  /// Проверка валидности количества цифр
  bool get isValidDigits {
    if (digits != null) {
      return digits == 6 || digits == 8; // стандартные значения
    }
    return true;
  }
}
