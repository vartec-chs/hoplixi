import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Improved custom toolbar for the editor.
///
/// - Groups commonly used buttons up front.
/// - Moves less-frequent actions into an overflow 'More' menu on narrow screens.
/// - Adds tooltips for discoverability and consistent spacing.
class Toolbar extends StatefulWidget {
  const Toolbar({super.key, required this.controller});

  final QuillController controller;

  @override
  State<Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<Toolbar> {
  bool _showSecondary = false;

  static const double _kHeight = 52;
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
        child: QuillToolbarHistoryButton(
          isUndo: true,
          controller: widget.controller,
        ),
      ),
      _wrapWithTooltip(
        message: 'Повторить',
        child: QuillToolbarHistoryButton(
          isUndo: false,
          controller: widget.controller,
        ),
      ),
      _wrapWithTooltip(
        message: 'Жирный',
        child: QuillToolbarToggleStyleButton(
          options: const QuillToolbarToggleStyleButtonOptions(),
          controller: widget.controller,
          attribute: Attribute.bold,
        ),
      ),
      _wrapWithTooltip(
        message: 'Курсив',
        child: QuillToolbarToggleStyleButton(
          options: const QuillToolbarToggleStyleButtonOptions(),
          controller: widget.controller,
          attribute: Attribute.italic,
        ),
      ),
      _wrapWithTooltip(
        message: 'Подчёркнутый',
        child: QuillToolbarToggleStyleButton(
          controller: widget.controller,
          attribute: Attribute.underline,
        ),
      ),
      _wrapWithTooltip(
        message: 'Очистить формат',
        child: QuillToolbarClearFormatButton(controller: widget.controller),
      ),
      const VerticalDivider(width: 12, thickness: 1),
      _wrapWithTooltip(
        message: 'Ссылка',
        child: QuillToolbarLinkStyleButton(controller: widget.controller),
      ),
    ];

    // Secondary (less used) buttons as widgets
    final secondary = <Widget>[
      // _wrapWithTooltip(
      //   message: 'Вставить изображение',
      //   child: QuillToolbarImageButton(
      //     controller: widget.controller,
      //     options: const QuillToolbarImageButtonOptions(),
      //   ),
      // ),
      // Video and Camera are disabled, so skip or show disabled
      // _wrapWithTooltip(
      //   message: 'Вставить видео',
      //   child: QuillToolbarVideoButton(controller: widget.controller),
      // ),
      // _wrapWithTooltip(
      //   message: 'Камера',
      //   child: QuillToolbarCameraButton(controller: widget.controller),
      // ),
      _wrapWithTooltip(
        message: 'Цвет текста',
        child: QuillToolbarColorButton(
          controller: widget.controller,
          isBackground: false,
        ),
      ),
      _wrapWithTooltip(
        message: 'Фон текста',
        child: QuillToolbarColorButton(
          controller: widget.controller,
          isBackground: true,
        ),
      ),
      _wrapWithTooltip(
        message: 'Маркированный список',
        child: QuillToolbarToggleStyleButton(
          controller: widget.controller,
          attribute: Attribute.ul,
        ),
      ),
      _wrapWithTooltip(
        message: 'Нумерованный список',
        child: QuillToolbarToggleStyleButton(
          controller: widget.controller,
          attribute: Attribute.ol,
        ),
      ),
      _wrapWithTooltip(
        message: 'Встроенный код',
        child: QuillToolbarToggleStyleButton(
          controller: widget.controller,
          attribute: Attribute.inlineCode,
        ),
      ),
      _wrapWithTooltip(
        message: 'Цитата',
        child: QuillToolbarToggleStyleButton(
          controller: widget.controller,
          attribute: Attribute.blockQuote,
        ),
      ),
    ];

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
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
                                child:
                                    QuillToolbarSelectHeaderStyleDropdownButton(
                                      controller: widget.controller,
                                    ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: _kIconSpacing,
                                ),
                                child:
                                    QuillToolbarSelectLineHeightStyleDropdownButton(
                                      controller: widget.controller,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Button to toggle secondary buttons
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: IconButton(
                        tooltip: _showSecondary
                            ? 'Скрыть дополнительные'
                            : 'Показать дополнительные',
                        icon: Icon(
                          _showSecondary
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                        onPressed: () {
                          setState(() {
                            _showSecondary = !_showSecondary;
                          });
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_showSecondary)
            SizedBox(
              height: _kHeight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: secondary),
              ),
            ),
        ],
      ),
    );
  }
}
