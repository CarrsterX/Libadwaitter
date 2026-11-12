import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../theme/adw_colors.dart';
import '../../theme/adw_curves.dart';
import '../../theme/adw_theme.dart';
import 'adw_button.dart';

/// Preference row containing an editable text field (`AdwEntryRow`).
///
/// Follows GNOME Libadwaita specifications:
/// - Descriptive title/label displayed above or inline.
/// - Pure Dart text entry built directly on [EditableText].
/// - Optional quick clear button (`showClearButton`).
/// - Optional apply confirmation button (`showApplyButton`) with [onApply] callback.
/// - Optional [prefix] and [suffix] slot widgets.
class AdwEntryRow extends StatefulWidget {
  final Widget? title;
  final TextEditingController? controller;
  final String? initialValue;
  final String? placeholder;
  final bool obscureText;
  final bool showClearButton;
  final bool showApplyButton;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onApply;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const AdwEntryRow({
    super.key,
    this.title,
    this.controller,
    this.initialValue,
    this.placeholder,
    this.obscureText = false,
    this.showClearButton = true,
    this.showApplyButton = false,
    this.onChanged,
    this.onSubmitted,
    this.onApply,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  State<AdwEntryRow> createState() => _AdwEntryRowState();
}

class _AdwEntryRowState extends State<AdwEntryRow> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _controller.addListener(_handleTextChange);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_handleTextChange);
    }
    super.dispose();
  }

  void _handleTextChange() {
    setState(() {});
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final hasText = _controller.text.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AdwCurves.shortDuration,
        curve: AdwCurves.standard,
        color: _isFocused
            ? theme.colors.cardBackground
            : (_isHovered
                ? theme.colors.hoverBackground
                : const Color(0x00000000)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            if (widget.prefix != null) ...[
              widget.prefix!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.title != null) ...[
                    DefaultTextStyle(
                      style: theme.typography.caption.copyWith(
                        color: _isFocused
                            ? theme.colors.accentColor
                            : theme.colors.secondaryForeground,
                        fontSize: 11,
                      ),
                      child: widget.title!,
                    ),
                    const SizedBox(height: 2),
                  ],
                  _AdwPureEditableText(
                    controller: _controller,
                    focusNode: _focusNode,
                    obscureText: widget.obscureText,
                    placeholder: widget.placeholder,
                    keyboardType: widget.keyboardType,
                    inputFormatters: widget.inputFormatters,
                    style: theme.typography.body.copyWith(
                      color: theme.colors.foreground,
                    ),
                    placeholderStyle: theme.typography.body.copyWith(
                      color: theme.colors.secondaryForeground.withOpacity(0.5),
                    ),
                    cursorColor: theme.colors.accentColor,
                    onChanged: widget.onChanged,
                    onSubmitted: (val) {
                      widget.onSubmitted?.call(val);
                      if (widget.showApplyButton) {
                        widget.onApply?.call(val);
                      }
                    },
                  ),
                ],
              ),
            ),
            if (widget.showClearButton && hasText) ...[
              const SizedBox(width: 6),
              _ClearButton(
                onPressed: () {
                  _controller.clear();
                  widget.onChanged?.call('');
                },
              ),
            ],
            if (widget.showApplyButton && hasText) ...[
              const SizedBox(width: 6),
              AdwButton.suggested(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                onPressed: () => widget.onApply?.call(_controller.text),
                child: const Text('Apply'),
              ),
            ],
            if (widget.suffix != null) ...[
              const SizedBox(width: 8),
              widget.suffix!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Password entry row with integrated visibility toggle (`AdwPasswordEntryRow`).
class AdwPasswordEntryRow extends StatefulWidget {
  final Widget? title;
  final TextEditingController? controller;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefix;

  const AdwPasswordEntryRow({
    super.key,
    this.title,
    this.controller,
    this.placeholder,
    this.onChanged,
    this.onSubmitted,
    this.prefix,
  });

  @override
  State<AdwPasswordEntryRow> createState() => _AdwPasswordEntryRowState();
}

class _AdwPasswordEntryRowState extends State<AdwPasswordEntryRow> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AdwEntryRow(
      title: widget.title,
      controller: widget.controller,
      placeholder: widget.placeholder,
      obscureText: _obscureText,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      prefix: widget.prefix,
      suffix: AdwButton.flat(
        padding: const EdgeInsets.all(6),
        onPressed: () => setState(() => _obscureText = !_obscureText),
        child: Text(
          _obscureText ? '👁' : '🙈',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

class _ClearButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _ClearButton({required this.onPressed});

  @override
  State<_ClearButton> createState() => _ClearButtonState();
}

class _ClearButtonState extends State<_ClearButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered
                ? theme.colors.secondaryForeground.withOpacity(0.3)
                : theme.colors.secondaryForeground.withOpacity(0.15),
          ),
          child: Center(
            child: Text(
              '✕',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: theme.colors.foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdwPureEditableText extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscureText;
  final String? placeholder;
  final TextStyle style;
  final TextStyle placeholderStyle;
  final Color cursorColor;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _AdwPureEditableText({
    required this.controller,
    required this.focusNode,
    required this.obscureText,
    this.placeholder,
    required this.style,
    required this.placeholderStyle,
    required this.cursorColor,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        if (placeholder != null && controller.text.isEmpty)
          Text(placeholder!, style: placeholderStyle),
        EditableText(
          controller: controller,
          focusNode: focusNode,
          style: style,
          cursorColor: cursorColor,
          backgroundCursorColor: const Color(0x33000000),
          obscureText: obscureText,
          keyboardType: keyboardType ?? TextInputType.text,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          selectionColor: cursorColor.withOpacity(0.3),
        ),
      ],
    );
  }
}

