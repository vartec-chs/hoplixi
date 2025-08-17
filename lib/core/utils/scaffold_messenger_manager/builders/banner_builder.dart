import 'package:flutter/material.dart';
import '../models/banner_data.dart';
import '../themes/banner_theme_provider.dart';
import '../scaffold_messenger_manager.dart';

abstract class BannerBuilder {
  MaterialBanner build(BuildContext context, BannerData data);
}

class ModernBannerBuilder implements BannerBuilder {
  final BannerThemeProvider themeProvider;

  const ModernBannerBuilder({required this.themeProvider});

  @override
  MaterialBanner build(BuildContext context, BannerData data) {
    // Автоматически перестраивается при изменении темы
    final textColor = themeProvider.getTextColor(context, data.type);
    final leading =
        data.leading ?? themeProvider.getLeading(context, data.type);
    final actions = data.actions ?? _buildActions(context, data, textColor);

    return MaterialBanner(
      content: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style:
            Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: textColor) ??
            TextStyle(color: textColor),
        child: _buildContent(context, data, textColor),
      ),
      leading: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: leading,
      ),
      actions: actions.map((action) {
        // Если это TextButton, обновляем его цвет текста с анимацией
        if (action is TextButton) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: TextButton(
              key: ValueKey(textColor.value),
              onPressed: action.onPressed,
              style: TextButton.styleFrom(
                backgroundColor: textColor.withOpacity(0.1),
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: textColor.withOpacity(0.3), width: 1),
                ),
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                child: action.child ?? const Text(''),
              ),
            ),
          );
        }
        return action;
      }).toList(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      forceActionsBelow: data.forceActionsBelow,
    );
  }

  Widget _buildContent(BuildContext context, BannerData data, Color textColor) {
    return Text(
      data.message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    BannerData data,
    Color textColor,
  ) {
    return [
      TextButton(
        onPressed: () {
          ScaffoldMessengerManager.instance.hideCurrentBanner();
        },
        style: TextButton.styleFrom(
          backgroundColor: textColor.withOpacity(0.1),
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: textColor.withOpacity(0.3), width: 1),
          ),
        ),
        child: Text(
          'Закрыть',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
      ),
    ];
  }
}

// Сохраняем старый билдер для обратной совместимости
class DefaultBannerBuilder extends ModernBannerBuilder {
  const DefaultBannerBuilder({required super.themeProvider});
}
