import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'copy_button.dart';

class OutputPanel extends StatefulWidget {
  const OutputPanel({
    super.key,
    required this.title,
    required this.text,
    this.subtitle,
    this.editable = false,
    this.onChanged,
    this.minLines = 4,
    /// When null, the field grows with content so the parent scroll view
    /// owns vertical scrolling (mobile-friendly).
    this.maxLines,
    this.footer,
    this.actions,
  });

  final String title;
  final String text;
  final String? subtitle;
  final bool editable;
  final ValueChanged<String>? onChanged;
  final int minLines;
  final int? maxLines;
  final Widget? footer;
  final List<Widget>? actions;

  @override
  State<OutputPanel> createState() => _OutputPanelState();
}

class _OutputPanelState extends State<OutputPanel> {
  late TextEditingController _controller;
  late FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
    _focus = FocusNode();
  }

  @override
  void didUpdateWidget(covariant OutputPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text &&
        widget.text != _controller.text &&
        !_focus.hasFocus) {
      _controller.text = widget.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inkElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.actions != null) ...widget.actions!,
                CopyButton(label: 'Copy', text: widget.text),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: widget.editable
                ? TextField(
                    controller: _controller,
                    focusNode: _focus,
                    onChanged: widget.onChanged,
                    // Growing field: parent scroll view handles page scroll.
                    maxLines: widget.maxLines,
                    minLines: widget.minLines,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13.5,
                      height: 1.45,
                      color: AppColors.text,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                : SelectableText(
                    widget.text.isEmpty ? '—' : widget.text,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13.5,
                      height: 1.45,
                      color: AppColors.text,
                    ),
                  ),
          ),
          if (widget.footer != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: widget.footer!,
            ),
          ],
        ],
      ),
    );
  }
}
