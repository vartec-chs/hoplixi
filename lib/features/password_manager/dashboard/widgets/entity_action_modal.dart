import 'package:flutter/material.dart';
import 'package:hoplixi/common/slider_button.dart';

/// Типы действий над сущностями
enum EntityActionType { edit, delete }

/// Данные действия над сущностью
class EntityAction {
  final EntityActionType type;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final VoidCallback onPressed;

  const EntityAction({
    required this.type,
    required this.title,
    this.subtitle,
    required this.icon,
    this.color,
    required this.onPressed,
  });
}

/// Универсальная модалка для действий с сущностями
class EntityActionModal extends StatefulWidget {
  final String entityTitle;
  final String entitySubtitle;
  final IconData entityIcon;
  final List<EntityAction> actions;
  final VoidCallback? onDeleteConfirmed;
  final bool isMobile;

  const EntityActionModal({
    super.key,
    required this.entityTitle,
    required this.entitySubtitle,
    required this.entityIcon,
    required this.actions,
    this.onDeleteConfirmed,
    this.isMobile = true,
  });

  @override
  State<EntityActionModal> createState() => _EntityActionModalState();
}

class _EntityActionModalState extends State<EntityActionModal>
    with TickerProviderStateMixin {
  bool _showDeleteConfirmation = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Запускаем анимацию появления
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmationDialog() {
    setState(() {
      _showDeleteConfirmation = true;
    });
  }

  void _hideDeleteConfirmation() {
    setState(() {
      _showDeleteConfirmation = false;
    });
  }

  void _handleDeleteConfirmed() {
    widget.onDeleteConfirmed?.call();
    Navigator.of(context).pop();
  }

  void _handleActionPressed(EntityAction action) {
    if (action.type == EntityActionType.delete) {
      _showDeleteConfirmationDialog();
    } else {
      action.onPressed();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isMobile) {
      // Мобильная версия - bottom sheet
      return _buildMobileBottomSheet(theme);
    } else {
      // Десктопная версия - центрированная модалка
      return _buildDesktopModal(theme);
    }
  }

  Widget _buildMobileBottomSheet(ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Модальное окно
          SlideTransition(
            position: _slideAnimation,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showDeleteConfirmation
                    ? _buildDeleteConfirmation(theme)
                    : _buildActionsList(theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopModal(ThemeData theme) {
    return Material(
      color: Colors.black54,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Предотвращаем закрытие при клике на модалку
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showDeleteConfirmation
                        ? _buildDeleteConfirmation(theme)
                        : _buildActionsList(theme),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsList(ThemeData theme) {
    return Container(
      key: const ValueKey('actions_list'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок с информацией о сущности
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.entityIcon,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.entityTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.entitySubtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.entitySubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Список действий
          ...widget.actions.map((action) => _buildActionItem(theme, action)),

          const SizedBox(height: 8),

          // Кнопка отмены
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Отмена',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(ThemeData theme, EntityAction action) {
    final isDangerous = action.type == EntityActionType.delete;
    final actionColor =
        action.color ??
        (isDangerous ? theme.colorScheme.error : theme.colorScheme.primary);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleActionPressed(action),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: actionColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: actionColor.withOpacity(0.1), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(action.icon, color: actionColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: actionColor,
                        ),
                      ),
                      if (action.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          action.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: actionColor.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteConfirmation(ThemeData theme) {
    return Container(
      key: const ValueKey('delete_confirmation'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Иконка предупреждения
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_outlined,
              color: theme.colorScheme.error,
              size: 32,
            ),
          ),

          const SizedBox(height: 16),

          // Заголовок подтверждения
          Text(
            'Удалить ${widget.entityTitle}?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Описание
          Text(
            'Это действие нельзя отменить. Все данные будут безвозвратно удалены.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Слайдер подтверждения удаления
          SliderButton(
            type: SliderButtonType.delete,
            text: 'Проведите для удаления',
            onSlideComplete: _handleDeleteConfirmed,
            width: double.infinity,
            resetAfterComplete: false,
          ),

          const SizedBox(height: 16),

          // Кнопка отмены
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _hideDeleteConfirmation,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Отмена',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Утилитарный класс для отображения модалки действий
class EntityActionModalHelper {
  /// Определяет, является ли устройство мобильным
  static bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  /// Показывает модалку с действиями для пароля
  static Future<void> showPasswordActions(
    BuildContext context, {
    required String passwordName,
    required String loginOrEmail,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final isMobile = _isMobile(context);

    if (isMobile) {
      return showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        enableDrag: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => EntityActionModal(
          entityTitle: passwordName,
          entitySubtitle: loginOrEmail,
          entityIcon: Icons.password,
          isMobile: true,
          actions: [
            EntityAction(
              type: EntityActionType.edit,
              title: 'Редактировать',
              subtitle: 'Изменить данные пароля',
              icon: Icons.edit_outlined,
              onPressed: onEdit,
            ),
            EntityAction(
              type: EntityActionType.delete,
              title: 'Удалить',
              subtitle: 'Безвозвратно удалить пароль',
              icon: Icons.delete_outline,
              onPressed: () {}, // Будет обработано в модалке
            ),
          ],
          onDeleteConfirmed: onDelete,
        ),
      );
    } else {
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => EntityActionModal(
          entityTitle: passwordName,
          entitySubtitle: loginOrEmail,
          entityIcon: Icons.password,
          isMobile: false,
          actions: [
            EntityAction(
              type: EntityActionType.edit,
              title: 'Редактировать',
              subtitle: 'Изменить данные пароля',
              icon: Icons.edit_outlined,
              onPressed: onEdit,
            ),
            EntityAction(
              type: EntityActionType.delete,
              title: 'Удалить',
              subtitle: 'Безвозвратно удалить пароль',
              icon: Icons.delete_outline,
              onPressed: () {}, // Будет обработано в модалке
            ),
          ],
          onDeleteConfirmed: onDelete,
        ),
      );
    }
  }

  /// Показывает модалку с действиями для заметки
  static Future<void> showNoteActions(
    BuildContext context, {
    required String noteTitle,
    required String noteContent,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final isMobile = _isMobile(context);

    if (isMobile) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => EntityActionModal(
          entityTitle: noteTitle,
          entitySubtitle: noteContent,
          entityIcon: Icons.note,
          isMobile: true,
          actions: [
            EntityAction(
              type: EntityActionType.edit,
              title: 'Редактировать',
              subtitle: 'Изменить содержимое заметки',
              icon: Icons.edit_outlined,
              onPressed: onEdit,
            ),
            EntityAction(
              type: EntityActionType.delete,
              title: 'Удалить',
              subtitle: 'Безвозвратно удалить заметку',
              icon: Icons.delete_outline,
              onPressed: () {}, // Будет обработано в модалке
            ),
          ],
          onDeleteConfirmed: onDelete,
        ),
      );
    } else {
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => EntityActionModal(
          entityTitle: noteTitle,
          entitySubtitle: noteContent,
          entityIcon: Icons.note,
          isMobile: false,
          actions: [
            EntityAction(
              type: EntityActionType.edit,
              title: 'Редактировать',
              subtitle: 'Изменить содержимое заметки',
              icon: Icons.edit_outlined,
              onPressed: onEdit,
            ),
            EntityAction(
              type: EntityActionType.delete,
              title: 'Удалить',
              subtitle: 'Безвозвратно удалить заметку',
              icon: Icons.delete_outline,
              onPressed: () {}, // Будет обработано в модалке
            ),
          ],
          onDeleteConfirmed: onDelete,
        ),
      );
    }
  }

  /// Показывает модалку с действиями для OTP
  static Future<void> showOtpActions(
    BuildContext context, {
    required String otpName,
    required String issuer,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final isMobile = _isMobile(context);

    if (isMobile) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => EntityActionModal(
          entityTitle: otpName,
          entitySubtitle: issuer,
          entityIcon: Icons.security,
          isMobile: true,
          actions: [
            EntityAction(
              type: EntityActionType.edit,
              title: 'Редактировать',
              subtitle: 'Изменить данные OTP',
              icon: Icons.edit_outlined,
              onPressed: onEdit,
            ),
            EntityAction(
              type: EntityActionType.delete,
              title: 'Удалить',
              subtitle: 'Безвозвратно удалить OTP',
              icon: Icons.delete_outline,
              onPressed: () {}, // Будет обработано в модалке
            ),
          ],
          onDeleteConfirmed: onDelete,
        ),
      );
    } else {
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => EntityActionModal(
          entityTitle: otpName,
          entitySubtitle: issuer,
          entityIcon: Icons.security,
          isMobile: false,
          actions: [
            EntityAction(
              type: EntityActionType.edit,
              title: 'Редактировать',
              subtitle: 'Изменить данные OTP',
              icon: Icons.edit_outlined,
              onPressed: onEdit,
            ),
            EntityAction(
              type: EntityActionType.delete,
              title: 'Удалить',
              subtitle: 'Безвозвратно удалить OTP',
              icon: Icons.delete_outline,
              onPressed: () {}, // Будет обработано в модалке
            ),
          ],
          onDeleteConfirmed: onDelete,
        ),
      );
    }
  }

  /// Универсальная функция для показа модалки
  static Future<void> showEntityActions(
    BuildContext context, {
    required String entityTitle,
    required String entitySubtitle,
    required IconData entityIcon,
    required List<EntityAction> actions,
    VoidCallback? onDeleteConfirmed,
  }) {
    final isMobile = _isMobile(context);

    if (isMobile) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => EntityActionModal(
          entityTitle: entityTitle,
          entitySubtitle: entitySubtitle,
          entityIcon: entityIcon,
          isMobile: true,
          actions: actions,
          onDeleteConfirmed: onDeleteConfirmed,
        ),
      );
    } else {
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => EntityActionModal(
          entityTitle: entityTitle,
          entitySubtitle: entitySubtitle,
          entityIcon: entityIcon,
          isMobile: false,
          actions: actions,
          onDeleteConfirmed: onDeleteConfirmed,
        ),
      );
    }
  }
}
