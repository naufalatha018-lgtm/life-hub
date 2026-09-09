import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../models/vault_file_item.dart';
import '../providers/vault_files_provider.dart';
import 'widgets/secure_file_preview_dialog.dart';

class SecureFileVaultView extends ConsumerWidget {
  const SecureFileVaultView({super.key});

  void _confirmDelete(BuildContext context, WidgetRef ref, VaultFileItem file) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xF2131722),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorderHighlighted),
        ),
        title: const Text('Delete Encrypted File?'),
        content: Text('Are you sure you want to permanently delete "${file.displayName}" from your secure vault?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(decryptedVaultFilesProvider.notifier).deleteVaultFile(file);
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(decryptedVaultFilesProvider);

    return filesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      ),
      error: (e, _) => Center(
        child: Text('Error loading vault: $e', style: const TextStyle(color: AppColors.expense)),
      ),
      data: (files) {
        if (files.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGlow.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: const Icon(
                      Icons.folder_zip_rounded,
                      size: 36,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Your Secure File Vault is Empty',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Import confidential documents, deeds, passports, receipts, and images.\nAll files are encrypted with AES-256-GCM before saving to disk.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(decryptedVaultFilesProvider.notifier).pickAndEncryptFiles(),
                    icon: const Icon(Icons.add_moderator_rounded, size: 20),
                    label: const Text('Encrypt & Import Files'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                ref.read(decryptedVaultFilesProvider.notifier).pickAndEncryptFiles(),
            icon: const Icon(Icons.add_moderator_rounded),
            label: const Text('Encrypt File', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;

              if (isWide) {
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 340,
                    mainAxisExtent: 150,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    return _buildFileCard(context, ref, files[index]);
                  },
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: files.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _buildFileCard(context, ref, files[index]);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFileCard(BuildContext context, WidgetRef ref, VaultFileItem file) {
    IconData icon;
    Color iconColor;

    if (file.isImage) {
      icon = Icons.image_rounded;
      iconColor = const Color(0xFF38BDF8); // Sky
    } else if (file.isPdf) {
      icon = Icons.picture_as_pdf_rounded;
      iconColor = AppColors.expense;
    } else if (file.isTextDoc) {
      icon = Icons.description_rounded;
      iconColor = AppColors.income;
    } else {
      icon = Icons.insert_drive_file_rounded;
      iconColor = AppColors.primaryLight;
    }

    return GlassContainer(
      blur: 8,
      backgroundColor: AppColors.surfaceVariant.withOpacity(0.4),
      borderColor: AppColors.cardBorderSubtle,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      file.formattedSize,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 18),
                color: AppColors.surface,
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'preview',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_rounded, size: 16, color: AppColors.primaryLight),
                        SizedBox(width: 8),
                        Text('Preview Decrypted', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Text('Export & Open', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.expense),
                        SizedBox(width: 8),
                        Text('Delete File', style: TextStyle(fontSize: 13, color: AppColors.expense)),
                      ],
                    ),
                  ),
                ],
                onSelected: (val) {
                  if (val == 'preview') {
                    SecureFilePreviewDialog.show(context, file);
                  } else if (val == 'export') {
                    ref.read(decryptedVaultFilesProvider.notifier).exportAndOpenFile(file);
                  } else if (val == 'delete') {
                    _confirmDelete(context, ref, file);
                  }
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryGlow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, size: 10, color: AppColors.primaryLight),
                    SizedBox(width: 4),
                    Text(
                      'AES-GCM',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => SecureFilePreviewDialog.show(context, file),
                icon: const Icon(Icons.remove_red_eye_rounded, size: 14),
                label: const Text('View', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
