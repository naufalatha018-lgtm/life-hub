import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../models/secure_note.dart';
import '../../providers/notes_crud_provider.dart';
import 'note_editor_dialog.dart';

class NoteCardWidget extends ConsumerWidget {
  const NoteCardWidget({super.key, required this.note});

  final SecureNote note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: note.isPinned ? AppColors.primaryLight.withValues(alpha: 0.5) : AppColors.cardBorder,
          width: note.isPinned ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => NoteEditorDialog(existingNote: note),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Title & Pin Action
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 18,
                        color: note.isPinned ? AppColors.primaryLight : AppColors.textMuted,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => ref.read(decryptedNotesProvider.notifier).togglePin(note.id),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: AppColors.surfaceVariant,
                      onSelected: (action) {
                        if (action == 'delete') {
                          ref.read(decryptedNotesProvider.notifier).deleteNote(note.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Note deleted')),
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: AppColors.expense, size: 18),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: AppColors.expense, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Content snippet
                Text(
                  note.content,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),

                // Tags & Date Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: note.tags.isNotEmpty
                          ? Wrap(
                              spacing: 6,
                              children: note.tags.take(3).map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: const TextStyle(color: AppColors.primaryLight, fontSize: 10),
                                  ),
                                );
                              }).toList(),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Text(
                      DateFormatter.formatRelative(note.updatedAt),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
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
