import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'setting_types.dart';
import 'auto_preferences_manager.dart';

/// Базовый виджет для редактирования настройки
abstract class SettingWidget extends StatefulWidget {
  const SettingWidget({super.key, required this.setting, this.onChanged});

  final SettingDefinition setting;
  final VoidCallback? onChanged;

  /// Фабрика для создания виджета по типу настройки
  static Widget create(SettingDefinition setting, {VoidCallback? onChanged}) {
    switch (setting.type) {
      case SettingType.boolean:
        return BooleanSettingWidget(setting: setting, onChanged: onChanged);
      case SettingType.string:
      case SettingType.multilineText:
      case SettingType.password:
        return StringSettingWidget(setting: setting, onChanged: onChanged);
      case SettingType.integer:
      case SettingType.integerRange:
        return IntegerSettingWidget(setting: setting, onChanged: onChanged);
      case SettingType.stringChoice:
        return ChoiceSettingWidget(setting: setting, onChanged: onChanged);
      case SettingType.action:
        return ActionSettingWidget(setting: setting, onChanged: onChanged);
      default:
        return UnsupportedSettingWidget(setting: setting);
    }
  }
}

/// Виджет для булевой настройки
class BooleanSettingWidget extends SettingWidget {
  const BooleanSettingWidget({
    super.key,
    required super.setting,
    super.onChanged,
  });

  @override
  State<BooleanSettingWidget> createState() => _BooleanSettingWidgetState();
}

class _BooleanSettingWidgetState extends State<BooleanSettingWidget> {
  late bool _value;
  final AutoPreferencesManager _manager = AutoPreferencesManager.instance;

  @override
  void initState() {
    super.initState();
    _value = _manager.getValue<bool>(widget.setting.key, defaultValue: false);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled =
        widget.setting.isEnabled &&
        !widget.setting.isReadOnly &&
        _manager.checkSettingDependencies(widget.setting.key);

    return ListTile(
      leading: widget.setting.icon != null
          ? Icon(_getIconData(widget.setting.icon!))
          : null,
      title: Text(widget.setting.title),
      subtitle: widget.setting.subtitle != null
          ? Text(widget.setting.subtitle!)
          : null,
      trailing: Switch(value: _value, onChanged: isEnabled ? _onChanged : null),
      enabled: isEnabled,
      onTap: isEnabled ? () => _onChanged(!_value) : null,
    );
  }

  void _onChanged(bool value) async {
    try {
      await _manager.setValue(widget.setting.key, value);
      setState(() {
        _value = value;
      });
      widget.onChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }
}

/// Виджет для строковой настройки
class StringSettingWidget extends SettingWidget {
  const StringSettingWidget({
    super.key,
    required super.setting,
    super.onChanged,
  });

  @override
  State<StringSettingWidget> createState() => _StringSettingWidgetState();
}

class _StringSettingWidgetState extends State<StringSettingWidget> {
  late TextEditingController _controller;
  final AutoPreferencesManager _manager = AutoPreferencesManager.instance;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final value = _manager.getValue<String>(
      widget.setting.key,
      defaultValue: '',
    );
    _controller = TextEditingController(text: value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stringSetting = widget.setting as StringSetting;
    final isEnabled =
        widget.setting.isEnabled &&
        !widget.setting.isReadOnly &&
        _manager.checkSettingDependencies(widget.setting.key);

    return ListTile(
      leading: widget.setting.icon != null
          ? Icon(_getIconData(widget.setting.icon!))
          : null,
      title: Text(widget.setting.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.setting.subtitle != null) Text(widget.setting.subtitle!),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            enabled: isEnabled,
            obscureText: stringSetting.isPassword,
            maxLines: stringSetting.isMultiline ? 3 : 1,
            maxLength: stringSetting.maxLength,
            decoration: InputDecoration(
              hintText: stringSetting.placeholder,
              errorText: _errorText,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: _onChanged,
          ),
        ],
      ),
    );
  }

  void _onChanged(String value) async {
    final error = widget.setting.validate(value);
    setState(() {
      _errorText = error;
    });

    if (error == null) {
      try {
        await _manager.setValue(widget.setting.key, value);
        widget.onChanged?.call();
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorText = e.toString();
          });
        }
      }
    }
  }
}

/// Виджет для числовой настройки
class IntegerSettingWidget extends SettingWidget {
  const IntegerSettingWidget({
    super.key,
    required super.setting,
    super.onChanged,
  });

  @override
  State<IntegerSettingWidget> createState() => _IntegerSettingWidgetState();
}

class _IntegerSettingWidgetState extends State<IntegerSettingWidget> {
  late int _value;
  late TextEditingController _controller;
  final AutoPreferencesManager _manager = AutoPreferencesManager.instance;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _value = _manager.getValue<int>(widget.setting.key, defaultValue: 0);
    _controller = TextEditingController(text: _value.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final integerSetting = widget.setting as IntegerSetting;
    final isEnabled =
        widget.setting.isEnabled &&
        !widget.setting.isReadOnly &&
        _manager.checkSettingDependencies(widget.setting.key);

    return ListTile(
      leading: widget.setting.icon != null
          ? Icon(_getIconData(widget.setting.icon!))
          : null,
      title: Text(widget.setting.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.setting.subtitle != null) Text(widget.setting.subtitle!),
          const SizedBox(height: 8),
          if (integerSetting.isSlider &&
              integerSetting.min != null &&
              integerSetting.max != null)
            _buildSlider(integerSetting, isEnabled)
          else
            _buildTextField(integerSetting, isEnabled),
        ],
      ),
    );
  }

  Widget _buildSlider(IntegerSetting setting, bool isEnabled) {
    return Column(
      children: [
        Slider(
          value: _value.toDouble(),
          min: setting.min!.toDouble(),
          max: setting.max!.toDouble(),
          divisions: (setting.max! - setting.min!) ~/ setting.step,
          label: '$_value${setting.unit ?? ''}',
          onChanged: isEnabled
              ? (value) {
                  setState(() {
                    _value = value.round();
                  });
                }
              : null,
          onChangeEnd: isEnabled
              ? (value) {
                  _onChanged(value.round());
                }
              : null,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${setting.min}${setting.unit ?? ''}'),
            Text('$_value${setting.unit ?? ''}'),
            Text('${setting.max}${setting.unit ?? ''}'),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(IntegerSetting setting, bool isEnabled) {
    return TextField(
      controller: _controller,
      enabled: isEnabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        suffixText: setting.unit,
        errorText: _errorText,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (value) {
        final intValue = int.tryParse(value);
        if (intValue != null) {
          _onChanged(intValue);
        }
      },
    );
  }

  void _onChanged(int value) async {
    final error = widget.setting.validate(value);
    setState(() {
      _errorText = error;
      _value = value;
      _controller.text = value.toString();
    });

    if (error == null) {
      try {
        await _manager.setValue(widget.setting.key, value);
        widget.onChanged?.call();
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorText = e.toString();
          });
        }
      }
    }
  }
}

/// Виджет для выбора из списка
class ChoiceSettingWidget extends SettingWidget {
  const ChoiceSettingWidget({
    super.key,
    required super.setting,
    super.onChanged,
  });

  @override
  State<ChoiceSettingWidget> createState() => _ChoiceSettingWidgetState();
}

class _ChoiceSettingWidgetState extends State<ChoiceSettingWidget> {
  late String? _value;
  final AutoPreferencesManager _manager = AutoPreferencesManager.instance;

  @override
  void initState() {
    super.initState();
    _value = _manager.getValue<String?>(widget.setting.key);
  }

  @override
  Widget build(BuildContext context) {
    final choiceSetting = widget.setting as ChoiceSetting;
    final isEnabled =
        widget.setting.isEnabled &&
        !widget.setting.isReadOnly &&
        _manager.checkSettingDependencies(widget.setting.key);

    return ListTile(
      leading: widget.setting.icon != null
          ? Icon(_getIconData(widget.setting.icon!))
          : null,
      title: Text(widget.setting.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.setting.subtitle != null) Text(widget.setting.subtitle!),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _value,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: choiceSetting.options.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: isEnabled ? _onChanged : null,
          ),
        ],
      ),
    );
  }

  void _onChanged(String? value) async {
    try {
      await _manager.setValue(widget.setting.key, value);
      setState(() {
        _value = value;
      });
      widget.onChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }
}

/// Виджет для действий (кнопок)
class ActionSettingWidget extends SettingWidget {
  const ActionSettingWidget({
    super.key,
    required super.setting,
    super.onChanged,
  });

  @override
  State<ActionSettingWidget> createState() => _ActionSettingWidgetState();
}

class _ActionSettingWidgetState extends State<ActionSettingWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final actionSetting = widget.setting as ActionSetting;
    final isEnabled =
        widget.setting.isEnabled &&
        !_isLoading &&
        AutoPreferencesManager.instance.checkSettingDependencies(
          widget.setting.key,
        );

    return ListTile(
      leading: widget.setting.icon != null
          ? Icon(_getIconData(widget.setting.icon!))
          : null,
      title: Text(widget.setting.title),
      subtitle: widget.setting.subtitle != null
          ? Text(widget.setting.subtitle!)
          : null,
      trailing: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : ElevatedButton(
              onPressed: isEnabled ? _onPressed : null,
              style: actionSetting.isDestructive
                  ? ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    )
                  : null,
              child: Text(actionSetting.buttonText ?? 'Выполнить'),
            ),
    );
  }

  void _onPressed() async {
    final actionSetting = widget.setting as ActionSetting;

    // Показать диалог подтверждения, если нужно
    if (actionSetting.confirmationMessage != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(widget.setting.title),
          content: Text(actionSetting.confirmationMessage!),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: actionSetting.isDestructive
                  ? ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    )
                  : null,
              child: const Text('Выполнить'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await actionSetting.action();
      widget.onChanged?.call();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Действие выполнено')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// Виджет для неподдерживаемых типов настроек
class UnsupportedSettingWidget extends StatelessWidget {
  const UnsupportedSettingWidget({super.key, required this.setting});

  final SettingDefinition setting;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.error_outline),
      title: Text(setting.title),
      subtitle: Text('Тип настройки "${setting.type}" не поддерживается'),
      enabled: false,
    );
  }
}

/// Вспомогательная функция для получения IconData по строке
IconData _getIconData(String iconName) {
  // Карта популярных иконок
  const iconMap = {
    'brightness_6': Icons.brightness_6,
    'language': Icons.language,
    'timer': Icons.timer,
    'lock_clock': Icons.lock_clock,
    'fingerprint': Icons.fingerprint,
    'pin': Icons.pin,
    'content_paste_off': Icons.content_paste_off,
    'screen_lock_portrait': Icons.screen_lock_portrait,
    'app_blocking': Icons.app_blocking,
    'view_compact': Icons.view_compact,
    'security': Icons.security,
    'label': Icons.label,
    'history': Icons.history,
    'format_list_numbered': Icons.format_list_numbered,
    'sort': Icons.sort,
    'straighten': Icons.straighten,
    'text_fields': Icons.text_fields,
    'tag': Icons.tag,
    'visibility_off': Icons.visibility_off,
    'keyboard': Icons.keyboard,
    'record_voice_over': Icons.record_voice_over,
    'folder': Icons.folder,
    'save': Icons.save,
    'compress': Icons.compress,
    'backup': Icons.backup,
    'schedule': Icons.schedule,
    'folder_special': Icons.folder_special,
    'delete_sweep': Icons.delete_sweep,
    'enhanced_encryption': Icons.enhanced_encryption,
    'bug_report': Icons.bug_report,
    'article': Icons.article,
    'clear_all': Icons.clear_all,
    'file_download': Icons.file_download,
    'restart_alt': Icons.restart_alt,
  };

  return iconMap[iconName] ?? Icons.settings;
}
