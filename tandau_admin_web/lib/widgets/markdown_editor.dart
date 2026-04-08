import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/app_colors.dart';

/// 📝 Rich Text Editor с Markdown тулбаром и preview
///
/// Поддерживает: Bold, Italic, Strikethrough, H1-H3, Lists,
/// Links, Images, Code blocks.
class MarkdownEditor extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final int minLines;

  const MarkdownEditor({
    super.key,
    required this.controller,
    this.label = 'Описание',
    this.enabled = true,
    this.minLines = 6,
  });

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  bool _showPreview = false;

  void _insertMarkdown(String prefix, {String suffix = '', String placeholder = ''}) {
    if (!widget.enabled) return;

    final TextEditingController ctrl = widget.controller;
    final String text = ctrl.text;
    final TextSelection selection = ctrl.selection;

    if (!selection.isValid) {
      // No selection — insert at end
      ctrl.text = '$text$prefix$placeholder$suffix';
      ctrl.selection = TextSelection.collapsed(
        offset: text.length + prefix.length,
      );
      return;
    }

    final String selected = selection.textInside(text);
    final String replacement = '$prefix${selected.isEmpty ? placeholder : selected}$suffix';

    ctrl.text = text.replaceRange(selection.start, selection.end, replacement);
    ctrl.selection = TextSelection(
      baseOffset: selection.start + prefix.length,
      extentOffset: selection.start + prefix.length + (selected.isEmpty ? placeholder.length : selected.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            Text(
              widget.label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            // Preview toggle
            _buildToggle(),
          ],
        ),
        const SizedBox(height: 8),

        // Toolbar
        if (widget.enabled && !_showPreview) _buildToolbar(),
        if (widget.enabled && !_showPreview) const SizedBox(height: 8),

        // Editor or Preview
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _showPreview ? _buildPreview() : _buildEditor(),
        ),
      ],
    );
  }

  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleBtn(
            icon: Icons.edit_rounded,
            label: 'Редактор',
            active: !_showPreview,
            onTap: () => setState(() => _showPreview = false),
          ),
          _buildToggleBtn(
            icon: Icons.visibility_rounded,
            label: 'Предпросмотр',
            active: _showPreview,
            onTap: () => setState(() => _showPreview = true),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? AppColors.primary : Colors.white38),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: active ? AppColors.primary : Colors.white38,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Wrap(
        spacing: 2,
        children: [
          _toolBtn(Icons.format_bold_rounded, 'Bold', () => _insertMarkdown('**', suffix: '**', placeholder: 'жирный')),
          _toolBtn(Icons.format_italic_rounded, 'Italic', () => _insertMarkdown('*', suffix: '*', placeholder: 'курсив')),
          _toolBtn(Icons.strikethrough_s_rounded, 'Strike', () => _insertMarkdown('~~', suffix: '~~', placeholder: 'зачёркнутый')),
          _divider(),
          _toolBtn(Icons.title_rounded, 'H1', () => _insertMarkdown('# ', placeholder: 'Заголовок 1')),
          _toolBtn(Icons.text_fields_rounded, 'H2', () => _insertMarkdown('## ', placeholder: 'Заголовок 2')),
          _toolBtn(Icons.text_format_rounded, 'H3', () => _insertMarkdown('### ', placeholder: 'Заголовок 3')),
          _divider(),
          _toolBtn(Icons.format_list_bulleted_rounded, 'List', () => _insertMarkdown('- ', placeholder: 'пункт списка')),
          _toolBtn(Icons.format_list_numbered_rounded, 'Num', () => _insertMarkdown('1. ', placeholder: 'нумерованный пункт')),
          _toolBtn(Icons.check_box_rounded, 'Check', () => _insertMarkdown('- [ ] ', placeholder: 'задача')),
          _divider(),
          _toolBtn(Icons.link_rounded, 'Link', () => _insertMarkdown('[', suffix: '](url)', placeholder: 'текст ссылки')),
          _toolBtn(Icons.image_rounded, 'Img', () => _insertMarkdown('![', suffix: '](url)', placeholder: 'alt текст')),
          _toolBtn(Icons.code_rounded, 'Code', () => _insertMarkdown('`', suffix: '`', placeholder: 'код')),
          _toolBtn(Icons.format_quote_rounded, 'Quote', () => _insertMarkdown('> ', placeholder: 'цитата')),
        ],
      ),
    );
  }

  Widget _toolBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: Colors.white60),
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildEditor() {
    return TextField(
      key: const ValueKey('editor'),
      controller: widget.controller,
      enabled: widget.enabled,
      maxLines: null,
      minLines: widget.minLines,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'monospace',
        fontSize: 14,
        height: 1.6,
      ),
      decoration: InputDecoration(
        hintText: 'Поддерживает **Markdown** разметку...',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
        filled: true,
        fillColor: AppColors.surfaceDark.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildPreview() {
    final String text = widget.controller.text;
    return Container(
      key: const ValueKey('preview'),
      width: double.infinity,
      constraints: BoxConstraints(minHeight: widget.minLines * 24.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: text.isEmpty
          ? Text(
              'Нет контента для предпросмотра',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            )
          : MarkdownBody(
              data: text,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
                h1: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                h2: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                h3: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                strong: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                em: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                listBullet: const TextStyle(color: AppColors.primary),
                blockquoteDecoration: BoxDecoration(
                  border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
                codeblockDecoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(8),
                ),
                code: const TextStyle(
                  color: Color(0xFF7EE787),
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            ),
    );
  }
}
