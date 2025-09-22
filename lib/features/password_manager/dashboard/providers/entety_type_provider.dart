import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

import '../models/entety_type.dart';

/// Состояние типа сущности
class EntityTypeState {
  final EntityType currentType;
  final Map<EntityType, bool> availableTypes;

  const EntityTypeState({
    required this.currentType,
    required this.availableTypes,
  });

  EntityTypeState copyWith({
    EntityType? currentType,
    Map<EntityType, bool>? availableTypes,
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

  bool _mapEquals(Map<EntityType, bool> a, Map<EntityType, bool> b) {
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
      currentType: EntityType.password,
      availableTypes: {for (final type in EntityType.values) type: true},
    );
  }

  /// Изменить текущий тип сущности
  void changeEntityType(EntityType newType) {
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
  void setAvailableTypes(Map<EntityType, bool> availableTypes) {
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
  void toggleTypeAvailability(EntityType type, bool isAvailable) {
    final newAvailableTypes = Map<EntityType, bool>.from(state.availableTypes);
    newAvailableTypes[type] = isAvailable;
    setAvailableTypes(newAvailableTypes);
  }

  /// Получить все доступные типы
  List<EntityType> get availableTypesList {
    return state.availableTypes.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  /// Проверить доступность типа
  bool isTypeAvailable(EntityType type) {
    return state.availableTypes[type] ?? false;
  }
}

/// Провайдер для контроллера типа сущности
final entityTypeControllerProvider =
    NotifierProvider<EntityTypeController, EntityTypeState>(
      EntityTypeController.new,
    );

/// Computed провайдер для текущего типа сущности
final currentEntityTypeProvider = Provider<EntityType>((ref) {
  return ref.watch(
    entityTypeControllerProvider.select((state) => state.currentType),
  );
});

/// Computed провайдер для доступных типов
final availableEntityTypesProvider = Provider<List<EntityType>>((ref) {
  final state = ref.watch(entityTypeControllerProvider);
  return state.availableTypes.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();
});

/// Computed провайдер для проверки доступности конкретного типа
Provider<bool> entityTypeAvailabilityProvider(EntityType type) {
  return Provider<bool>((ref) {
    return ref.watch(
      entityTypeControllerProvider.select(
        (state) => state.availableTypes[type] ?? false,
      ),
    );
  });
}
