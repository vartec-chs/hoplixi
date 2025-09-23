import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entety_type.dart';

enum FilterTab {
  all('Все', Icons.list),
  favorites('Избранные', Icons.star),
  frequent('Часто используемые', Icons.access_time),
  archived('Архив', Icons.archive);

  final String label;
  final IconData icon;
  const FilterTab(this.label, this.icon);

  /// Получить доступные вкладки для типа сущности
  static List<FilterTab> getAvailableTabsForEntity(EntityType entityType) {
    switch (entityType) {
      case EntityType.password:
        return [
          FilterTab.all,
          FilterTab.favorites,
          FilterTab.frequent,
          FilterTab.archived,
        ];
      case EntityType.note:
        return [FilterTab.all, FilterTab.favorites, FilterTab.archived];
      case EntityType.otp:
        return [FilterTab.all, FilterTab.favorites, FilterTab.archived];
    }
  }
}
