import 'package:freezed_annotation/freezed_annotation.dart';
import 'base_filter.dart';

part 'password_filter.freezed.dart';
part 'password_filter.g.dart';

enum PasswordSortField {
  name,
  url,
  username,
  createdAt,
  modifiedAt,
  lastAccessed,
  usedCount,
  strength,
}

/// Порог, после которого пароль считается "часто используемым"
const int kFrequentUsedThreshold = 100;

@freezed
abstract class PasswordFilter with _$PasswordFilter {
  const factory PasswordFilter({
    required BaseFilter base,
    String? name, // фильтр по названию
    String? url, // фильтр по URL
    String? username, // фильтр по имени пользователя
    bool? hasUrl, // есть ли URL
    bool? hasUsername, // есть ли имя пользователя
    bool? hasTotp, // есть ли TOTP
    bool? isCompromised, // скомпрометированный пароль
    bool? isExpired, // истекший пароль
    bool? isFrequent, // часто используемый (usedCount >= threshold)
    PasswordSortField? sortField,
  }) = _PasswordFilter;

  factory PasswordFilter.create({
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

    int? minUsedCount,
    int? maxUsedCount,
    DateTime? expiresAfter,
    DateTime? expiresBefore,

    PasswordSortField? sortField,
  }) {
    final normalizedName = name?.trim();
    final normalizedUrl = url?.trim();
    final normalizedUsername = username?.trim();

    // Валидация количества использований
    int? validMinUsedCount = minUsedCount;
    int? validMaxUsedCount = maxUsedCount;

    if (minUsedCount != null && minUsedCount < 0) {
      validMinUsedCount = 0;
    }

    if (maxUsedCount != null && maxUsedCount < 0) {
      validMaxUsedCount = null;
    }

    if (validMinUsedCount != null &&
        validMaxUsedCount != null &&
        validMinUsedCount > validMaxUsedCount) {
      // Если минимум больше максимума, сбрасываем максимум
      validMaxUsedCount = null;
    }

    return PasswordFilter(
      base: base ?? const BaseFilter(),
      name: normalizedName?.isEmpty == true ? null : normalizedName,
      url: normalizedUrl?.isEmpty == true ? null : normalizedUrl,
      username: normalizedUsername?.isEmpty == true ? null : normalizedUsername,
      hasUrl: hasUrl,
      hasUsername: hasUsername,
      hasTotp: hasTotp,
      isCompromised: isCompromised,
      isExpired: isExpired,
      isFrequent: isFrequent,

      sortField: sortField,
    );
  }

  factory PasswordFilter.fromJson(Map<String, dynamic> json) =>
      _$PasswordFilterFromJson(json);
}

extension PasswordFilterHelpers on PasswordFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (name != null) return true;
    if (url != null) return true;
    if (username != null) return true;
    if (hasUrl != null) return true;
    if (hasUsername != null) return true;
    if (hasTotp != null) return true;
    if (isCompromised != null) return true;
    if (isExpired != null) return true;
    if (isFrequent != null) return true;
    // if (minStrength != null) return true;
    // if (maxStrength != null) return true;
    // if (minUsedCount != null) return true;
    // if (maxUsedCount != null) return true;
    // if (expiresAfter != null || expiresBefore != null) return true;
    return false;
  }

  /// Проверка валидности диапазона количества использований
  bool get isValidUsedCountRange {
    // if (minUsedCount != null && maxUsedCount != null) {
    //   return minUsedCount! <= maxUsedCount!;
    // }
    return true;
  }

  /// Проверка валидности диапазона силы пароля
  bool get isValidStrengthRange {
    // if (minStrength != null && maxStrength != null) {
    //   return minStrength!.index <= maxStrength!.index;
    // }
    return true;
  }

  /// Генерация SQL условия для количества использований
  String usedCountSqlCondition(String usedCountColumn) {
    final conditions = <String>[];

    // if (minUsedCount != null) {
    //   conditions.add('$usedCountColumn >= $minUsedCount');
    // }

    // if (maxUsedCount != null) {
    //   conditions.add('$usedCountColumn <= $maxUsedCount');
    // }

    if (conditions.isEmpty) {
      return '1=1';
    }

    return conditions.join(' AND ');
  }

  /// Генерация SQL условия для часто используемых паролей
  String frequentSqlCondition(String usedCountColumn) {
    if (isFrequent == null) {
      return '1=1';
    } else if (isFrequent == true) {
      return '$usedCountColumn >= $kFrequentUsedThreshold';
    } else {
      return '$usedCountColumn < $kFrequentUsedThreshold';
    }
  }

  /// Генерация SQL условия для силы пароля
  String strengthSqlCondition(String strengthColumn) {
    final conditions = <String>[];

    // if (minStrength != null) {
    //   conditions.add('$strengthColumn >= ${minStrength!.index}');
    // }

    // if (maxStrength != null) {
    //   conditions.add('$strengthColumn <= ${maxStrength!.index}');
    // }

    if (conditions.isEmpty) {
      return '1=1';
    }

    return conditions.join(' AND ');
  }

  /// Генерация SQL условия для даты истечения
  String expirationSqlCondition(String expirationColumn) {
    final conditions = <String>[];

    // if (expiresAfter != null) {
    //   conditions.add('$expirationColumn >= ?');
    // }

    // if (expiresBefore != null) {
    //   conditions.add('$expirationColumn <= ?');
    // }

    if (conditions.isEmpty) {
      return '1=1';
    }

    return conditions.join(' AND ');
  }

  /// Получение параметров для SQL запроса по дате истечения
  List<DateTime> get expirationSqlParams {
    final params = <DateTime>[];

    // if (expiresAfter != null) {
    //   params.add(expiresAfter!);
    // }

    // if (expiresBefore != null) {
    //   params.add(expiresBefore!);
    // }

    return params;
  }
}
