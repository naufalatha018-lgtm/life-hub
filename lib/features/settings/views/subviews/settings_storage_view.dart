import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/backup/backup_service.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_container.dart';
import '../../providers/settings_providers.dart';

class SettingsStorageView extends ConsumerWidget {
  const SettingsStorageView({super.key});

  void _showExportBackupDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _ExportBackupDialog(),
    );
  }

  void _showRestoreBackupDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _RestoreBackupDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final storageAsync = ref.watch(storageStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          strings.settingsStorageTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.settingsStorageSubtitle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Storage Statistics Breakdown
            storageAsync.when(
              data: (stats) {
                final total = stats.totalSizeBytes > 0 ? stats.totalSizeBytes : 1;
                final dbRatio = (stats.dbSizeBytes / total).clamp(0.05, 0.9);
                final vaultRatio = (stats.vaultSizeBytes / total).clamp(0.05, 0.9);
                final cacheRatio = (stats.cacheSizeBytes / total).clamp(0.05, 0.9);

                return GlassContainer(
                  blur: 10,
                  backgroundColor: AppColors.surface,
                  borderColor: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(18),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            strings.totalStorageTitle,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            stats.formattedTotalSize,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Multi-segment progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          children: [
                            Expanded(
                              flex: (dbRatio * 100).toInt(),
                              child: Container(height: 10, color: const Color(0xFF6366F1)),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              flex: (vaultRatio * 100).toInt(),
                              child: Container(height: 10, color: const Color(0xFFEC4899)),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              flex: (cacheRatio * 100).toInt(),
                              child: Container(height: 10, color: const Color(0xFF10B981)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildStorageRow(const Color(0xFF6366F1), strings.databaseStorageTitle, stats.formattedDbSize, '${stats.transactionCount} tx, ${stats.taskCount} tasks'),
                      const SizedBox(height: 8),
                      _buildStorageRow(const Color(0xFFEC4899), strings.vaultFilesStorageTitle, stats.formattedVaultSize, '${stats.noteCount} notes, ${stats.vaultFileCount} files'),
                      const SizedBox(height: 8),
                      _buildStorageRow(const Color(0xFF10B981), strings.tempBuffersStorageTitle, stats.formattedCacheSize, 'Auto-managed cache'),

                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.cardBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final reclaimed = await ref.read(storageStatsProvider.notifier).clearTemporaryCache();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(reclaimed > 0
                                    ? '${strings.clearCacheNotice} (${StorageStats.formatBytes(reclaimed)})'
                                    : strings.cacheOptimizedNotice),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                        label: Text(strings.clearStorageCacheButton),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading storage: $err'),
            ),
            const SizedBox(height: 20),

            // Encrypted Backup & Restore Section (.lhpack)
            GlassContainer(
              blur: 10,
              backgroundColor: AppColors.surface,
              borderColor: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGlow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.archive_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.backupRestoreTitle,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              strings.backupRestoreSubtitle,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showExportBackupDialog(context, ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.upload_rounded, size: 16),
                          label: Text(strings.exportBackupButton),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRestoreBackupDialog(context, ref),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: Text(strings.importBackupButton),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageRow(Color color, String label, String size, String details) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(details, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ),
        Text(size, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ExportBackupDialog extends ConsumerStatefulWidget {
  const _ExportBackupDialog();

  @override
  ConsumerState<_ExportBackupDialog> createState() => _ExportBackupDialogState();
}

class _ExportBackupDialogState extends ConsumerState<_ExportBackupDialog> {
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  String? _exportedPayload;

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    if (_passCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final payload = await ref.read(backupServiceProvider).createEncryptedBackup(
            password: _passCtrl.text,
          );
      if (mounted) {
        setState(() {
          _exportedPayload = payload;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
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
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.exportBackupButton,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_exportedPayload == null) ...[
                Text(
                  strings.backupPasswordHint,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: strings.enterBackupPassword,
                    prefixIcon: const Icon(Icons.key_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(strings.cancel),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _export,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: _isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(strings.exportBackupButton),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.income.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.income, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings.backupExportSuccess,
                          style: const TextStyle(color: AppColors.income, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Salin paket cadangan terenkripsi .lhpack Anda di bawah ini:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: SelectableText(
                    _exportedPayload!,
                    maxLines: 4,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _exportedPayload!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(strings.copied)),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(strings.copy),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: Text(strings.close),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RestoreBackupDialog extends ConsumerStatefulWidget {
  const _RestoreBackupDialog();

  @override
  ConsumerState<_RestoreBackupDialog> createState() => _RestoreBackupDialogState();
}

class _RestoreBackupDialogState extends ConsumerState<_RestoreBackupDialog> {
  final _payloadCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _payloadCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    if (_payloadCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final summary = await ref.read(backupServiceProvider).restoreEncryptedBackup(
            packageData: _payloadCtrl.text,
            password: _passCtrl.text,
          );

      await ref.read(storageStatsProvider.notifier).refreshStats();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Berhasil memulihkan: ${summary.transactionCount} transaksi, ${summary.taskCount} tugas, ${summary.noteCount} catatan!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString();
          _isLoading = false;
        });
      }
    }
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
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.importBackupButton,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_errorMsg != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_errorMsg!, style: const TextStyle(color: AppColors.expense, fontSize: 12)),
                ),
              TextField(
                controller: _payloadCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Tempel Paket Data .lhpack (Base64)',
                  hintText: 'LHPACK1...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: strings.enterBackupPassword,
                  prefixIcon: const Icon(Icons.key_rounded),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(strings.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _restore,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(strings.importBackupButton),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
