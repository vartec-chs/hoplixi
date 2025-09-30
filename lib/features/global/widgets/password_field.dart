import 'package:flutter/material.dart';
import 'package:hoplixi/features/global/widgets/text_field.dart';

/// Кастомное поле для пароля с поддержкой показа/скрытия пароля
class CustomPasswordField extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final String? errorText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final Widget? prefixIcon;
  final EdgeInsetsGeometry? contentPadding;
  final InputDecoration? decoration;
  final bool filled;

  const CustomPasswordField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.onChanged,
    this.validator,
    this.onSaved,
    this.errorText,
    this.onFieldSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.textInputAction,
    this.focusNode,
    this.onTap,
    this.prefixIcon,
    this.contentPadding,
    this.decoration,
    this.filled = true,
  });

  @override
  State<CustomPasswordField> createState() => _CustomPasswordFieldState();
}

class _CustomPasswordFieldState extends State<CustomPasswordField> {
  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Используем базовую декорацию или переданную
    final baseDecoration =
        widget.decoration ??
        primaryInputDecoration(
          context,
          labelText: widget.label,
          hintText: widget.hintText,
          errorText: widget.errorText,
          filled: widget.filled,
        );

    final effectiveDecoration = baseDecoration.copyWith(
      suffixIcon: IconButton(
        icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
        onPressed: _togglePasswordVisibility,
        tooltip: _obscureText ? 'Показать пароль' : 'Скрыть пароль',
      ),
      prefixIcon: widget.prefixIcon ?? const Icon(Icons.lock),
      contentPadding: widget.contentPadding,
    );

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      onChanged: widget.onChanged,
      validator: widget.validator ?? (value) => widget.errorText,
      onSaved: widget.onSaved,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      focusNode: widget.focusNode,
      onTap: widget.onTap,
      decoration: effectiveDecoration,
      onFieldSubmitted: widget.onFieldSubmitted,
    );
  }
}
