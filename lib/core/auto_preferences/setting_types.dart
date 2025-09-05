/// Типы настроек, поддерживаемые автоматической системой
enum SettingType {
  /// Булево значение (переключатель)
  boolean,

  /// Строковое значение
  string,

  /// Целое число
  integer,

  /// Число с плавающей точкой
  double,

  /// Выбор из списка строк
  stringChoice,

  /// Выбор из списка чисел
  integerChoice,

  /// Диапазон целых чисел (ползунок)
  integerRange,

  /// Диапазон чисел с плавающей точкой (ползунок)
  doubleRange,

  /// Путь к файлу
  filePath,

  /// Путь к папке
  directoryPath,

  /// Цвет
  color,

  /// Дата
  date,

  /// Время
  time,

  /// Дата и время
  dateTime,

  /// Список строк
  stringList,

  /// Многострочный текст
  multilineText,

  /// Пароль (скрытый ввод)
  password,

  /// Режим темы (системная/светлая/темная)
  themeMode,

  /// Язык приложения
  language,

  /// Кнопка-действие (без значения)
  action,
}

/// Базовый класс для всех типов настроек
abstract class SettingDefinition {
  const SettingDefinition({
    required this.key,
    required this.title,
    this.subtitle,
    this.description,
    this.category,
    this.subcategory,
    this.icon,
    this.isVisible = true,
    this.isEnabled = true,
    this.isReadOnly = false,
    this.isRequired = false,
    this.order = 0,
    this.dependencies = const [],
    this.validator,
    this.onChanged,
  });

  /// Уникальный ключ настройки
  final String key;

  /// Название настройки
  final String title;

  /// Подпись (краткое описание)
  final String? subtitle;

  /// Подробное описание
  final String? description;

  /// Категория настройки
  final String? category;

  /// Подкатегория настройки
  final String? subcategory;

  /// Иконка
  final String? icon;

  /// Видимость настройки
  final bool isVisible;

  /// Доступность для редактирования
  final bool isEnabled;

  /// Только для чтения
  final bool isReadOnly;

  /// Обязательное поле
  final bool isRequired;

  /// Порядок сортировки в категории
  final int order;

  /// Зависимости от других настроек
  final List<String> dependencies;

  /// Валидатор значения
  final String? Function(dynamic value)? validator;

  /// Колбек при изменении значения
  final void Function(dynamic value)? onChanged;

  /// Тип настройки
  SettingType get type;

  /// Значение по умолчанию
  dynamic get defaultValue;

  /// Получить текущее значение из SharedPreferences
  dynamic getCurrentValue();

  /// Установить значение в SharedPreferences
  Future<void> setValue(dynamic value);

  /// Проверить зависимости
  bool checkDependencies();

  /// Валидировать значение
  String? validate(dynamic value) {
    if (validator != null) {
      return validator!(value);
    }
    return null;
  }
}

/// Настройка булевого типа
class BooleanSetting extends SettingDefinition {
  const BooleanSetting({
    required super.key,
    required super.title,
    super.subtitle,
    super.description,
    super.category,
    super.subcategory,
    super.icon,
    super.isVisible,
    super.isEnabled,
    super.isReadOnly,
    super.isRequired,
    super.order,
    super.dependencies,
    super.validator,
    super.onChanged,
    this.defaultValue = false,
  });

  @override
  final bool defaultValue;

  @override
  SettingType get type => SettingType.boolean;

  @override
  bool getCurrentValue() {
    // Значение будет получено через менеджер настроек
    return defaultValue; // Заглушка - реальное значение получает менеджер
  }

  @override
  Future<void> setValue(dynamic value) async {
    // Здесь будет сохранение в SharedPreferences
    if (value is bool) {
      onChanged?.call(value);
    }
  }

  @override
  bool checkDependencies() {
    // Проверка зависимостей
    return true; // Заглушка
  }
}

/// Настройка строкового типа
class StringSetting extends SettingDefinition {
  const StringSetting({
    required super.key,
    required super.title,
    super.subtitle,
    super.description,
    super.category,
    super.subcategory,
    super.icon,
    super.isVisible,
    super.isEnabled,
    super.isReadOnly,
    super.isRequired,
    super.order,
    super.dependencies,
    super.validator,
    super.onChanged,
    this.defaultValue = '',
    this.maxLength,
    this.minLength,
    this.placeholder,
    this.isMultiline = false,
    this.isPassword = false,
  });

  @override
  final String defaultValue;

  /// Максимальная длина строки
  final int? maxLength;

  /// Минимальная длина строки
  final int? minLength;

  /// Подсказка для ввода
  final String? placeholder;

  /// Многострочный ввод
  final bool isMultiline;

  /// Скрытый ввод (пароль)
  final bool isPassword;

  @override
  SettingType get type => isPassword
      ? SettingType.password
      : (isMultiline ? SettingType.multilineText : SettingType.string);

  @override
  String getCurrentValue() {
    return defaultValue; // Заглушка
  }

  @override
  Future<void> setValue(dynamic value) async {
    if (value is String) {
      onChanged?.call(value);
    }
  }

  @override
  bool checkDependencies() {
    return true; // Заглушка
  }

  @override
  String? validate(dynamic value) {
    final baseValidation = super.validate(value);
    if (baseValidation != null) return baseValidation;

    if (value is! String) return 'Неверный тип данных';

    if (isRequired && value.isEmpty) {
      return 'Поле обязательно для заполнения';
    }

    if (minLength != null && value.length < minLength!) {
      return 'Минимальная длина: $minLength символов';
    }

    if (maxLength != null && value.length > maxLength!) {
      return 'Максимальная длина: $maxLength символов';
    }

    return null;
  }
}

/// Настройка числового типа
class IntegerSetting extends SettingDefinition {
  const IntegerSetting({
    required super.key,
    required super.title,
    super.subtitle,
    super.description,
    super.category,
    super.subcategory,
    super.icon,
    super.isVisible,
    super.isEnabled,
    super.isReadOnly,
    super.isRequired,
    super.order,
    super.dependencies,
    super.validator,
    super.onChanged,
    this.defaultValue = 0,
    this.min,
    this.max,
    this.step = 1,
    this.unit,
    this.isSlider = false,
  });

  @override
  final int defaultValue;

  /// Минимальное значение
  final int? min;

  /// Максимальное значение
  final int? max;

  /// Шаг изменения
  final int step;

  /// Единица измерения
  final String? unit;

  /// Использовать ползунок вместо поля ввода
  final bool isSlider;

  @override
  SettingType get type =>
      isSlider ? SettingType.integerRange : SettingType.integer;

  @override
  int getCurrentValue() {
    return defaultValue; // Заглушка
  }

  @override
  Future<void> setValue(dynamic value) async {
    if (value is int) {
      onChanged?.call(value);
    }
  }

  @override
  bool checkDependencies() {
    return true; // Заглушка
  }

  @override
  String? validate(dynamic value) {
    final baseValidation = super.validate(value);
    if (baseValidation != null) return baseValidation;

    if (value is! int) return 'Неверный тип данных';

    if (min != null && value < min!) {
      return 'Минимальное значение: $min';
    }

    if (max != null && value > max!) {
      return 'Максимальное значение: $max';
    }

    return null;
  }
}

/// Настройка выбора из списка
class ChoiceSetting extends SettingDefinition {
  const ChoiceSetting({
    required super.key,
    required super.title,
    super.subtitle,
    super.description,
    super.category,
    super.subcategory,
    super.icon,
    super.isVisible,
    super.isEnabled,
    super.isReadOnly,
    super.isRequired,
    super.order,
    super.dependencies,
    super.validator,
    super.onChanged,
    required this.options,
    this.defaultValue,
  });

  /// Список вариантов выбора
  final Map<String, String> options; // value -> label

  @override
  final String? defaultValue;

  @override
  SettingType get type => SettingType.stringChoice;

  @override
  String? getCurrentValue() {
    return defaultValue; // Заглушка
  }

  @override
  Future<void> setValue(dynamic value) async {
    if (value is String?) {
      onChanged?.call(value);
    }
  }

  @override
  bool checkDependencies() {
    return true; // Заглушка
  }

  @override
  String? validate(dynamic value) {
    final baseValidation = super.validate(value);
    if (baseValidation != null) return baseValidation;

    if (value is! String? && value != null) return 'Неверный тип данных';

    final stringValue = value as String?;

    if (isRequired && (stringValue == null || stringValue.isEmpty)) {
      return 'Необходимо выбрать значение';
    }

    if (stringValue != null && !options.containsKey(stringValue)) {
      return 'Недопустимое значение';
    }

    return null;
  }
}

/// Настройка-действие (кнопка)
class ActionSetting extends SettingDefinition {
  const ActionSetting({
    required super.key,
    required super.title,
    super.subtitle,
    super.description,
    super.category,
    super.subcategory,
    super.icon,
    super.isVisible,
    super.isEnabled,
    super.order,
    super.dependencies,
    required this.action,
    this.buttonText,
    this.confirmationMessage,
    this.isDestructive = false,
  });

  /// Действие при нажатии кнопки
  final Future<void> Function() action;

  /// Текст кнопки
  final String? buttonText;

  /// Сообщение подтверждения
  final String? confirmationMessage;

  /// Деструктивное действие (красная кнопка)
  final bool isDestructive;

  @override
  SettingType get type => SettingType.action;

  @override
  get defaultValue => null;

  @override
  getCurrentValue() => null;

  @override
  Future<void> setValue(value) async {
    // Действия не имеют значений
  }

  @override
  bool checkDependencies() {
    return true; // Заглушка
  }
}
