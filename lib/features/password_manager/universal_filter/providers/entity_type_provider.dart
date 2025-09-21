import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

/// Универсальные типы сущностей для фильтрации
enum UniversalEntityType {
  password('password', 'Пароли'),
  note('note', 'Заметки'),
  otp('otp', 'OTP/2FA'),
  attachment('attachment', 'Вложения');

  const UniversalEntityType(this.id, this.label);

  final String id;
  final String label;

  /// Получить тип по идентификатору
  static UniversalEntityType? fromId(String id) {
    try {
      return UniversalEntityType.values.firstWhere((type) => type.id == id);
    } catch (e) {
      logError('Неизвестный тип сущности', error: e, data: {'id': id});
      return null;
    }
  }
}

/// Состояние типа сущности
class EntityTypeState {
  final UniversalEntityType currentType;
  final Map<UniversalEntityType, bool> availableTypes;

  const EntityTypeState({
    required this.currentType,
    required this.availableTypes,
  });

  EntityTypeState copyWith({
    UniversalEntityType? currentType,
    Map<UniversalEntityType, bool>? availableTypes,
  }) {
    return EntityTypeState(
      currentType: currentType ?? this.currentType,
      availableTypes: availableTypes ?? this.availableTypes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EntityTypeState &&
        other.currentType == currentType &&
        _mapEquals(other.availableTypes, availableTypes);
  }

  @override
  int get hashCode => Object.hash(currentType, availableTypes);

  bool _mapEquals(
    Map<UniversalEntityType, bool> a,
    Map<UniversalEntityType, bool> b,
  ) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Контроллер для управления типом сущности
class EntityTypeController extends Notifier<EntityTypeState> {
  @override
  EntityTypeState build() {
    // Инициализируем с паролями по умолчанию
    return EntityTypeState(
      currentType: UniversalEntityType.password,
      availableTypes: {
        for (final type in UniversalEntityType.values) type: true,
      },
    );
  }

  /// Изменить текущий тип сущности
  void changeEntityType(UniversalEntityType newType) {
    if (!state.availableTypes[newType]!) {
      logWarning(
        'Попытка выбрать недоступный тип сущности',
        data: {
          'requestedType': newType.id,
          'availableTypes': state.availableTypes.keys.map((e) => e.id).toList(),
        },
      );
      return;
    }

    logInfo(
      'Изменение типа сущности',
      data: {'oldType': state.currentType.id, 'newType': newType.id},
    );

    state = state.copyWith(currentType: newType);
  }

  /// Установить доступные типы сущностей
  void setAvailableTypes(Map<UniversalEntityType, bool> availableTypes) {
    // Проверяем, что текущий тип остается доступным
    final currentTypeAvailable = availableTypes[state.currentType] ?? false;

    final newState = state.copyWith(availableTypes: availableTypes);

    // Если текущий тип стал недоступным, выбираем первый доступный
    if (!currentTypeAvailable) {
      final firstAvailable = availableTypes.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .firstOrNull;

      if (firstAvailable != null) {
        state = newState.copyWith(currentType: firstAvailable);
        logInfo(
          'Автоматическое переключение на доступный тип',
          data: {'newType': firstAvailable.id},
        );
      } else {
        logWarning('Нет доступных типов сущностей');
        state = newState;
      }
    } else {
      state = newState;
    }
  }

  /// Включить/выключить доступность типа
  void toggleTypeAvailability(UniversalEntityType type, bool isAvailable) {
    final newAvailableTypes = Map<UniversalEntityType, bool>.from(
      state.availableTypes,
    );
    newAvailableTypes[type] = isAvailable;
    setAvailableTypes(newAvailableTypes);
  }

  /// Получить все доступные типы
  List<UniversalEntityType> get availableTypesList {
    return state.availableTypes.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  /// Проверить доступность типа
  bool isTypeAvailable(UniversalEntityType type) {
    return state.availableTypes[type] ?? false;
  }
}

/// Провайдер для контроллера типа сущности
final entityTypeControllerProvider =
    NotifierProvider<EntityTypeController, EntityTypeState>(
      () => EntityTypeController(),
    );

/// Computed провайдер для текущего типа сущности
final currentEntityTypeProvider = Provider<UniversalEntityType>((ref) {
  return ref.watch(
    entityTypeControllerProvider.select((state) => state.currentType),
  );
});

/// Computed провайдер для доступных типов
final availableEntityTypesProvider = Provider<List<UniversalEntityType>>((ref) {
  final state = ref.watch(entityTypeControllerProvider);
  return state.availableTypes.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();
});

/// Computed провайдер для проверки доступности конкретного типа
Provider<bool> entityTypeAvailabilityProvider(UniversalEntityType type) {
  return Provider<bool>((ref) {
    return ref.watch(
      entityTypeControllerProvider.select(
        (state) => state.availableTypes[type] ?? false,
      ),
    );
  });
}
