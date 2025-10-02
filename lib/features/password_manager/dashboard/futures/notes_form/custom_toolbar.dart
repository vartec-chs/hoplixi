import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

/// Improved custom toolbar for the editor.
///
/// - Groups commonly used buttons up front.
/// - Moves less-frequent actions into an overflow 'More' menu on narrow screens.
/// - Adds tooltips for discoverability and consistent spacing.
class CustomToolbar extends StatelessWidget {
  const CustomToolbar({super.key, required this.controller});

  final QuillController controller;

  static const double _kHeight = 44;
  static const double _kIconSpacing = 6;

  Widget _wrapWithTooltip({required String message, required Widget child}) {
    return Tooltip(
      message: message,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _kIconSpacing),
        child: SizedBox(height: _kHeight, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Primary (frequently used) buttons
    final primary = <Widget>[
      _wrapWithTooltip(
        message: 'Отменить',
        child: QuillToolbarHistoryButton(isUndo: true, controller: controller),
      ),
      _wrapWithTooltip(
        message: 'Повторить',
        child: QuillToolbarHistoryButton(isUndo: false, controller: controller),
      ),
      _wrapWithTooltip(
        message: 'Жирный',
        child: QuillToolbarToggleStyleButton(
          options: const QuillToolbarToggleStyleButtonOptions(),
          controller: controller,
          attribute: Attribute.bold,
        ),
      ),
      _wrapWithTooltip(
        message: 'Курсив',
        child: QuillToolbarToggleStyleButton(
          options: const QuillToolbarToggleStyleButtonOptions(),
          controller: controller,
          attribute: Attribute.italic,
        ),
      ),
      _wrapWithTooltip(
        message: 'Подчёркнутый',
        child: QuillToolbarToggleStyleButton(
          controller: controller,
          attribute: Attribute.underline,
        ),
      ),
      _wrapWithTooltip(
        message: 'Очистить формат',
        child: QuillToolbarClearFormatButton(controller: controller),
      ),
      const VerticalDivider(width: 12, thickness: 1),
      _wrapWithTooltip(
        message: 'Ссылка',
        child: QuillToolbarLinkStyleButton(controller: controller),
      ),
    ];

    // Secondary (less used) buttons
    final secondary = <PopupMenuEntry<int>>[
      PopupMenuItem<int>(
        value: 1,
        child: Row(
          children: [
            const Icon(Icons.image),
            const SizedBox(width: 8),
            const Text('Вставить изображение'),
            const Spacer(),
            QuillToolbarImageButton(controller: controller),
          ],
        ),
      ),
      PopupMenuItem<int>(
        value: 2,
        child: Row(
          children: [
            const Icon(Icons.videocam),
            const SizedBox(width: 8),
            const Text('Вставить видео'),
            const Spacer(),
            QuillToolbarVideoButton(controller: controller),
          ],
        ),
      ),
      PopupMenuItem<int>(
        value: 3,
        child: Row(
          children: [
            const Icon(Icons.camera_alt),
            const SizedBox(width: 8),
            const Text('Камера'),
            const Spacer(),
            QuillToolbarCameraButton(controller: controller),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<int>(
        value: 4,
        child: Row(
          children: [
            const Icon(Icons.format_color_text),
            const SizedBox(width: 8),
            const Text('Цвет текста'),
            const Spacer(),
            QuillToolbarColorButton(
              controller: controller,
              isBackground: false,
            ),
          ],
        ),
      ),
      PopupMenuItem<int>(
        value: 5,
        child: Row(
          children: [
            const Icon(Icons.format_color_fill),
            const SizedBox(width: 8),
            const Text('Фон текста'),
            const Spacer(),
            QuillToolbarColorButton(controller: controller, isBackground: true),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<int>(
        value: 6,
        child: Row(
          children: [
            const Icon(Icons.format_list_bulleted),
            const SizedBox(width: 8),
            const Text('Списки и отступы'),
            const Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QuillToolbarToggleStyleButton(
                  controller: controller,
                  attribute: Attribute.ul,
                ),
                QuillToolbarToggleStyleButton(
                  controller: controller,
                  attribute: Attribute.ol,
                ),
              ],
            ),
          ],
        ),
      ),
      PopupMenuItem<int>(
        value: 7,
        child: Row(
          children: [
            const Icon(Icons.code),
            const SizedBox(width: 8),
            const Text('Код / Цитата'),
            const Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QuillToolbarToggleStyleButton(
                  controller: controller,
                  attribute: Attribute.inlineCode,
                ),
                QuillToolbarToggleStyleButton(
                  controller: controller,
                  attribute: Attribute.blockQuote,
                ),
              ],
            ),
          ],
        ),
      ),
    ];

    return Material(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.04),
      child: SizedBox(
        height: _kHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 680;

            return Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...primary,
                        if (!isNarrow) ...[
                          const VerticalDivider(width: 12, thickness: 1),
                          // show header and line height selectors inline on wide screens
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: _kIconSpacing,
                            ),
                            child: QuillToolbarSelectHeaderStyleDropdownButton(
                              controller: controller,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: _kIconSpacing,
                            ),
                            child:
                                QuillToolbarSelectLineHeightStyleDropdownButton(
                                  controller: controller,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Overflow menu for narrow screens or additional actions
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: PopupMenuButton<int>(
                    tooltip: 'Ещё',
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (_) => secondary,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
