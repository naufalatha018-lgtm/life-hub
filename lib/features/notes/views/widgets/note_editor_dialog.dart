import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/secure_note.dart';
import '../../providers/notes_crud_provider.dart';

class NoteEditorDialog extends ConsumerStatefulWidget {
  const NoteEditorDialog({super.key, this.existingNote});

  final SecureNote? existingNote;

  @override
  ConsumerState<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends ConsumerState<NoteEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagInputController;
  late List<String> _tags;
  late bool _isPinned;

  @override
  void initState() {
    super.initState();
    final note = widget.existingNote;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _tagInputController = TextEditingController();
    _tags = List.from(note?.tags ?? []);
    _isPinned = note?.isPinned ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addTag() {
    final text = _tagInputController.text.trim();
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _tagInputController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (widget.existingNote == null) {
      await ref.read(decryptedNotesProvider.notifier).addNote(
            title: title,
            content: content,
            tags: _tags,
            isPinned: _isPinned,
          );
    } else {
      await ref.read(decryptedNotesProvider.notifier).updateNote(
            widget.existingNote!.copyWith(
              title: title,
              content: content,
              tags: _tags,
              isPinned: _isPinned,
            ),
          );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGlow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.existingNote == null ? strings.newNote : strings.editNote,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: _isPinned ? 'Unpin' : 'Pin Note',
                          icon: Icon(
                            _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                            color: _isPinned ? AppColors.primary : AppColors.textMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _isPinned = !_isPinned),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title input
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: strings.noteTitleLabel,
                    hintText: '...',
                    prefixIcon: const Icon(Icons.title_rounded, color: AppColors.textMuted),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return strings.noteTitleLabel;
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Tags input & list
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagInputController,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: strings.noteTagsLabel,
                          hintText: 'e.g. personal, ideas',
                          prefixIcon: const Icon(Icons.tag_rounded, color: AppColors.textMuted, size: 18),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                            onPressed: _addTag,
                          ),
                        ),
                        onSubmitted: (_) => _addTag(),
                      ),
                    ),
                  ],
                ),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                        deleteIcon: const Icon(Icons.close, size: 12),
                        backgroundColor: AppColors.surfaceVariant,
                        onDeleted: () => _removeTag(tag),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 14),

                // Note Content Field
                TextFormField(
                  controller: _contentController,
                  maxLines: 8,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    labelText: strings.noteContentLabel,
                    hintText: '...',
                    alignLabelWithHint: true,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return strings.noteContentLabel;
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(strings.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        child: Text(widget.existingNote == null ? strings.save : strings.update),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
