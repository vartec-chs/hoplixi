import 'package:flutter/material.dart';
import 'package:hoplixi/common/button.dart';
import 'dart:math';

/// Виджет для генерации случайных паролей
class PasswordGenerator extends StatefulWidget {
  /// Колбек для установки сгенерированного пароля
  final Function(String password) onPasswordGenerated;

  const PasswordGenerator({super.key, required this.onPasswordGenerated});

  @override
  State<PasswordGenerator> createState() => _PasswordGeneratorState();
}

class _PasswordGeneratorState extends State<PasswordGenerator> {
  int _passwordLength = 12;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  bool _excludeSimilar = false;

  static const String _uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
  static const String _numberChars = '0123456789';
  static const String _symbolChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
  static const String _similarChars = 'il1Lo0O';

  /// Генерация случайного пароля
  String _generatePassword() {
    String characterPool = '';

    if (_includeUppercase) characterPool += _uppercaseChars;
    if (_includeLowercase) characterPool += _lowercaseChars;
    if (_includeNumbers) characterPool += _numberChars;
    if (_includeSymbols) characterPool += _symbolChars;

    if (_excludeSimilar) {
      for (String char in _similarChars.split('')) {
        characterPool = characterPool.replaceAll(char, '');
      }
    }

    if (characterPool.isEmpty) {
      return 'Password123!'; // Fallback пароль
    }

    final random = Random.secure();
    String password = '';

    // Обеспечиваем наличие хотя бы одного символа из каждой включенной категории
    if (_includeUppercase && _uppercaseChars.isNotEmpty) {
      String chars = _excludeSimilar
          ? _uppercaseChars.replaceAll(RegExp(r'[il1Lo0O]'), '')
          : _uppercaseChars;
      if (chars.isNotEmpty) {
        password += chars[random.nextInt(chars.length)];
      }
    }

    if (_includeLowercase && _lowercaseChars.isNotEmpty) {
      String chars = _excludeSimilar
          ? _lowercaseChars.replaceAll(RegExp(r'[il1Lo0O]'), '')
          : _lowercaseChars;
      if (chars.isNotEmpty) {
        password += chars[random.nextInt(chars.length)];
      }
    }

    if (_includeNumbers && _numberChars.isNotEmpty) {
      String chars = _excludeSimilar
          ? _numberChars.replaceAll(RegExp(r'[10O]'), '')
          : _numberChars;
      if (chars.isNotEmpty) {
        password += chars[random.nextInt(chars.length)];
      }
    }

    if (_includeSymbols && _symbolChars.isNotEmpty) {
      password += _symbolChars[random.nextInt(_symbolChars.length)];
    }

    // Заполняем остальную длину случайными символами
    while (password.length < _passwordLength) {
      password += characterPool[random.nextInt(characterPool.length)];
    }

    // Перемешиваем символы
    List<String> passwordList = password.split('');
    passwordList.shuffle(random);

    return passwordList.join('');
  }

  /// Оценка сложности пароля
  String _getPasswordStrength(String password) {
    int score = 0;

    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;
    if (password.contains(RegExp(r'[A-Z]'))) score += 1;
    if (password.contains(RegExp(r'[a-z]'))) score += 1;
    if (password.contains(RegExp(r'[0-9]'))) score += 1;
    if (password.contains(RegExp(r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]'))) {
      score += 1;
    }

    if (score < 3) return 'Слабый';
    if (score < 5) return 'Средний';
    return 'Сильный';
  }

  /// Цвет индикатора сложности
  Color _getStrengthColor(String strength) {
    switch (strength) {
      case 'Слабый':
        return Colors.red;
      case 'Средний':
        return Colors.orange;
      case 'Сильный':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final generatedPassword = _generatePassword();
    final strength = _getPasswordStrength(generatedPassword);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Icon(Icons.security, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Генератор паролей',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Длина пароля
          Row(
            children: [
              Text('Длина: ', style: theme.textTheme.bodyMedium),
              Expanded(
                child: Slider(
                  value: _passwordLength.toDouble(),
                  min: 6,
                  max: 50,
                  divisions: 44,
                  label: _passwordLength.toString(),
                  onChanged: (value) {
                    setState(() {
                      _passwordLength = value.round();
                    });
                  },
                ),
              ),
              SizedBox(
                width: 30,
                child: Text(
                  _passwordLength.toString(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Параметры генерации
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _OptionChip(
                label: 'A-Z',
                value: _includeUppercase,
                onChanged: (value) {
                  setState(() {
                    _includeUppercase = value;
                  });
                },
              ),
              _OptionChip(
                label: 'a-z',
                value: _includeLowercase,
                onChanged: (value) {
                  setState(() {
                    _includeLowercase = value;
                  });
                },
              ),
              _OptionChip(
                label: '0-9',
                value: _includeNumbers,
                onChanged: (value) {
                  setState(() {
                    _includeNumbers = value;
                  });
                },
              ),
              _OptionChip(
                label: '!@#',
                value: _includeSymbols,
                onChanged: (value) {
                  setState(() {
                    _includeSymbols = value;
                  });
                },
              ),
              _OptionChip(
                label: 'Исключить похожие',
                value: _excludeSimilar,
                onChanged: (value) {
                  setState(() {
                    _excludeSimilar = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Предпросмотр пароля
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        generatedPassword,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStrengthColor(strength).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        strength,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _getStrengthColor(strength),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Кнопка применения
          SmoothButton(
            label: 'Использовать этот пароль',
            onPressed: () {
              widget.onPasswordGenerated(generatedPassword);
            },
            type: SmoothButtonType.filled,
            size: SmoothButtonSize.medium,
            isFullWidth: true,
            icon: const Icon(Icons.check, size: 18),
          ),
        ],
      ),
    );
  }
}

/// Виджет для переключения опций генератора
class _OptionChip extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool) onChanged;

  const _OptionChip({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label, style: theme.textTheme.labelSmall),
      selected: value,
      onSelected: onChanged,
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
      side: BorderSide(
        color: value
            ? theme.colorScheme.primary.withOpacity(0.5)
            : theme.colorScheme.outline.withOpacity(0.3),
      ),
    );
  }
}
