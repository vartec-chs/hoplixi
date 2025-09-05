import 'package:flutter/material.dart';
import 'preference_definition.dart';

/// Базовый виджет для редактирования настройки
abstract class PreferenceEditor extends StatelessWidget {
  final PreferenceDefinition preference;
  final VoidCallback? onChanged;

  const PreferenceEditor({super.key, required this.preference, this.onChanged});

  /// Создать подходящий редактор для типа настройки
  static Widget create(
    PreferenceDefinition preference, {
    VoidCallback? onChanged,
  }) {
    switch (preference.type) {
      case PreferenceType.bool:
        return BoolPreferenceEditor(
          preference: preference,
          onChanged: onChanged,
        );
      case PreferenceType.int:
        return IntPreferenceEditor(
          preference: preference,
          onChanged: onChanged,
        );
      case PreferenceType.string:
        return StringPreferenceEditor(
          preference: preference,
          onChanged: onChanged,
        );
      case PreferenceType.themeMode:
        return ThemeModePreferenceEditor(
          preference: preference,
          onChanged: onChanged,
        );
      case PreferenceType.stringList:
        return StringListPreferenceEditor(
          preference: preference,
          onChanged: onChanged,
        );
      case PreferenceType.dateTime:
        return DateTimePreferenceEditor(
          preference: preference,
          onChanged: onChanged,
        );
      case PreferenceType.double:
        return DoublePreferenceEditor(
          preference: preference,
          onChanged: onChanged,
        );
    }
  }
}

/// Редактор для boolean настроек
class BoolPreferenceEditor extends PreferenceEditor {
  const BoolPreferenceEditor({
    super.key,
    required super.preference,
    super.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value = preference.getBoolValue();

    return SwitchListTile(
      title: Text(preference.title),
      subtitle: preference.subtitle != null ? Text(preference.subtitle!) : null,
      secondary: preference.icon != null ? Icon(preference.icon) : null,
      value: value,
      onChanged: preference.isReadOnly
          ? null
          : (newValue) async {
              await preference.setValue(newValue);
              onChanged?.call();
            },
    );
  }
}

/// Редактор для integer настроек
class IntPreferenceEditor extends PreferenceEditor {
  const IntPreferenceEditor({
    super.key,
    required super.preference,
    super.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value = preference.getIntValue();

    if (preference.allowedValues != null) {
      // Dropdown для предустановленных значений
      return ListTile(
        leading: preference.icon != null ? Icon(preference.icon) : null,
        title: Text(preference.title),
        subtitle: preference.subtitle != null
            ? Text(preference.subtitle!)
            : null,
        trailing: DropdownButton<int>(
          value: value,
          onChanged: preference.isReadOnly
              ? null
              : (newValue) async {
                  if (newValue != null) {
                    await preference.setValue(newValue);
                    onChanged?.call();
                  }
                },
          items: preference.allowedValues!.cast<int>().map((val) {
            return DropdownMenuItem(value: val, child: Text(val.toString()));
          }).toList(),
        ),
      );
    } else {
      // Slider для диапазона значений
      return ListTile(
        leading: preference.icon != null ? Icon(preference.icon) : null,
        title: Text(preference.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (preference.subtitle != null) Text(preference.subtitle!),
            Text('Текущее значение: $value'),
          ],
        ),
        trailing: SizedBox(
          width: 150,
          child: Slider(
            value: value.toDouble(),
            min: (preference.minValue ?? 0).toDouble(),
            max: (preference.maxValue ?? 100).toDouble(),
            divisions:
                (preference.maxValue ?? 100) - (preference.minValue ?? 0),
            label: value.toString(),
            onChanged: preference.isReadOnly
                ? null
                : (newValue) async {
                    await preference.setValue(newValue.round());
                    onChanged?.call();
                  },
          ),
        ),
      );
    }
  }
}

/// Редактор для double настроек
class DoublePreferenceEditor extends PreferenceEditor {
  const DoublePreferenceEditor({
    super.key,
    required super.preference,
    super.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value = preference.getDoubleValue();

    return ListTile(
      leading: preference.icon != null ? Icon(preference.icon) : null,
      title: Text(preference.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (preference.subtitle != null) Text(preference.subtitle!),
          Text('Текущее значение: ${value.toStringAsFixed(2)}'),
        ],
      ),
      trailing: SizedBox(
        width: 150,
        child: Slider(
          value: value,
          min: (preference.minValue ?? 0).toDouble(),
          max: (preference.maxValue ?? 100).toDouble(),
          label: value.toStringAsFixed(2),
          onChanged: preference.isReadOnly
              ? null
              : (newValue) async {
                  await preference.setValue(newValue);
                  onChanged?.call();
                },
        ),
      ),
    );
  }
}

/// Редактор для string настроек
class StringPreferenceEditor extends PreferenceEditor {
  const StringPreferenceEditor({
    super.key,
    required super.preference,
    super.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value = preference.getStringValue();

    if (preference.allowedValues != null) {
      // Dropdown для предустановленных значений
      return ListTile(
        leading: preference.icon != null ? Icon(preference.icon) : null,
        title: Text(preference.title),
        subtitle: preference.subtitle != null
            ? Text(preference.subtitle!)
            : null,
        trailing: DropdownButton<String>(
          value: value,
          onChanged: preference.isReadOnly
              ? null
              : (newValue) async {
                  if (newValue != null) {
                    await preference.setValue(newValue);
                    onChanged?.call();
                  }
                },
          items: preference.allowedValues!.cast<String>().map((val) {
            String displayText = val;
            switch (val) {
              case 'system':
                displayText = 'Системный';
                break;
              case 'ru':
                displayText = 'Русский';
                break;
              case 'en':
                displayText = 'English';
                break;
              case 'de':
                displayText = 'Deutsch';
                break;
              case 'fr':
                displayText = 'Français';
                break;
              case 'es':
                displayText = 'Español';
                break;
            }
            return DropdownMenuItem(value: val, child: Text(displayText));
          }).toList(),
        ),
      );
    } else {
      // Текстовое поле для свободного ввода
      return ListTile(
        leading: preference.icon != null ? Icon(preference.icon) : null,
        title: Text(preference.title),
        subtitle: preference.subtitle != null
            ? Text(preference.subtitle!)
            : null,
        trailing: SizedBox(
          width: 200,
          child: TextFormField(
            initialValue: value,
            enabled: !preference.isReadOnly,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onFieldSubmitted: (newValue) async {
              await preference.setValue(newValue);
              onChanged?.call();
            },
          ),
        ),
      );
    }
  }
}

/// Редактор для ThemeMode настроек
class ThemeModePreferenceEditor extends PreferenceEditor {
  const ThemeModePreferenceEditor({
    super.key,
    required super.preference,
    super.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value =
        preference.getCurrentValue() as ThemeMode? ?? ThemeMode.system;

    return ListTile(
      leading: preference.icon != null ? Icon(preference.icon) : null,
      title: Text(preference.title),
      subtitle: preference.subtitle != null ? Text(preference.subtitle!) : null,
      trailing: DropdownButton<ThemeMode>(
        value: value,
        onChanged: preference.isReadOnly
            ? null
            : (newValue) async {
                if (newValue != null) {
                  await preference.setValue(newValue);
                  onChanged?.call();
                }
              },
        items: const [
          DropdownMenuItem(value: ThemeMode.system, child: Text('Системная')),
          DropdownMenuItem(value: ThemeMode.light, child: Text('Светлая')),
          DropdownMenuItem(value: ThemeMode.dark, child: Text('Темная')),
        ],
      ),
    );
  }
}

/// Редактор для List<String> настроек
class StringListPreferenceEditor extends PreferenceEditor {
  const StringListPreferenceEditor({
    super.key,
    required super.preference,
    super.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value = preference.getStringListValue();

    return ExpansionTile(
      leading: preference.icon != null ? Icon(preference.icon) : null,
      title: Text(preference.title),
      subtitle: Text('${value.length} элементов'),
      children: [
        if (value.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Text('Список пуст'))
        else
          ...value.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return ListTile(
              title: Text(item),
              leading: Text('${index + 1}'),
              dense: true,
            );
          }),
      ],
    );
  }
}

/// Редактор для DateTime настроек
class DateTimePreferenceEditor extends PreferenceEditor {
  const DateTimePreferenceEditor({
    super.key,
    required super.preference,
    super.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value = preference.getCurrentValue() as DateTime?;

    return ListTile(
      leading: preference.icon != null ? Icon(preference.icon) : null,
      title: Text(preference.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (preference.subtitle != null) Text(preference.subtitle!),
          Text(preference.getDisplayValue()),
        ],
      ),
      trailing: preference.isReadOnly
          ? null
          : IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: value ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(
                      value ?? DateTime.now(),
                    ),
                  );
                  if (time != null) {
                    final newDateTime = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                    await preference.setValue(newDateTime);
                    onChanged?.call();
                  }
                }
              },
            ),
    );
  }
}
