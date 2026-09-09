import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/vault_file_item.dart';
import '../../providers/vault_files_provider.dart';

class SecureFilePreviewDialog extends ConsumerStatefulWidget {
  final VaultFileItem fileItem;

  const SecureFilePreviewDialog({super.key, required this.fileItem});

  static Future<void> show(BuildContext context, VaultFileItem fileItem) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SecureFilePreviewDialog(fileItem: fileItem),
    );
  }

  @override
  ConsumerState<SecureFilePreviewDialog> createState() => _SecureFilePreviewDialogState();
}

class _SecureFilePreviewDialogState extends ConsumerState<SecureFilePreviewDialog> {
  Uint8List? _decryptedBytes;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  Future<void> _loadBytes() async {
    try {
      final bytes = await ref
          .read(decryptedVaultFilesProvider.notifier)
          .getDecryptedBytes(widget.fileItem);
      if (mounted) {
        setState(() {
          _decryptedBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportAndOpen() async {
    try {
      await ref
          .read(decryptedVaultFilesProvider.notifier)
          .exportAndOpenFile(widget.fileItem);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.fileItem;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 600),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardBorderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGlow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.isImage
                          ? Icons.image_rounded
                          : (item.isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded),
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${item.formattedSize} • Encrypted Document',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content Area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorderSubtle),
                  ),
                  child: _buildBody(item),
                ),
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Decrypted transiently in RAM only',
                    style: TextStyle(
                      color: AppColors.income.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _exportAndOpen,
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: const Text('Export & Open'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          side: const BorderSide(color: AppColors.cardBorderSubtle),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(VaultFileItem item) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_clock_rounded, size: 40, color: AppColors.expense),
              const SizedBox(height: 10),
              Text(
                'Decryption Error: $_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.expense, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_decryptedBytes == null || _decryptedBytes!.isEmpty) {
      return const Center(
        child: Text('Empty file', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    if (item.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: InteractiveViewer(
          child: Center(
            child: Image.memory(
              _decryptedBytes!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child: Text('Could not render image format', style: TextStyle(color: AppColors.textMuted)),
              ),
            ),
          ),
        ),
      );
    }

    if (item.isTextDoc) {
      String textContent = '';
      try {
        textContent = utf8.decode(_decryptedBytes!);
      } catch (_) {
        textContent = String.fromCharCodes(_decryptedBytes!);
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          textContent,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontFamily: 'monospace',
            height: 1.5,
          ),
        ),
      );
    }

    // Generic doc / PDF
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
            size: 64,
            color: item.isPdf ? AppColors.expense : AppColors.primaryLight,
          ),
          const SizedBox(height: 14),
          Text(
            item.displayName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Format: ${item.mimeType}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _exportAndOpen,
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('Open with External System App'),
          ),
        ],
      ),
    );
  }
}
