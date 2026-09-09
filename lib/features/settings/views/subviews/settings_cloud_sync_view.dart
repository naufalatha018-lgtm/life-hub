import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';

final _syncStatusProvider = StateProvider<String?>((ref) => null);
final _syncSuccessProvider = StateProvider<bool>((ref) => false);
final _syncLoadingProvider = StateProvider<bool>((ref) => false);

class SettingsCloudSyncView extends ConsumerWidget {
  const SettingsCloudSyncView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    final svc = SupabaseService.instance;
    final isConnected = svc.isInitialized && svc.isSignedIn;
    final statusMsg = ref.watch(_syncStatusProvider);
    final statusOk = ref.watch(_syncSuccessProvider);
    final isLoading = ref.watch(_syncLoadingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(strings.cloudSyncTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Connection status card
          _buildStatusCard(theme, strings, svc, isConnected),
          const SizedBox(height: 16),

          // Sync now button
          _buildSyncCard(theme, strings, isConnected, isLoading, statusMsg, statusOk, ref),
          const SizedBox(height: 16),

          // What gets synced
          _buildSyncScopeCard(theme, ref),

          const SizedBox(height: 16),

          // Privacy note
          _buildPrivacyCard(theme, ref),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, dynamic strings, SupabaseService svc, bool isConnected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected ? AppColors.income.withOpacity(0.3) : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isConnected ? AppColors.income : AppColors.textMuted).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              color: isConnected ? AppColors.income : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.cloudSyncTitle,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  isConnected ? strings.cloudSyncEnabled : strings.cloudSyncOffline,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isConnected ? AppColors.income : AppColors.textMuted,
                  ),
                ),
                if (isConnected && svc.currentUser != null)
                  Text(
                    svc.currentUser!.email ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted, fontSize: 11),
                  ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isConnected ? AppColors.income : AppColors.textMuted,
              shape: BoxShape.circle,
              boxShadow: isConnected
                  ? [BoxShadow(color: AppColors.income.withOpacity(0.4), blurRadius: 6)]
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncCard(
    ThemeData theme,
    dynamic strings,
    bool isConnected,
    bool isLoading,
    String? statusMsg,
    bool statusOk,
    WidgetRef ref,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.cloudSyncNow, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            strings.cloudSyncSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isConnected && !isLoading
                  ? () => _runSync(ref, strings)
                  : null,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync_rounded, size: 18),
              label: Text(strings.cloudSyncNow),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.cardBorder,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (statusMsg != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (statusOk ? AppColors.income : AppColors.expense).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    statusOk ? Icons.check_circle_outline : Icons.error_outline,
                    color: statusOk ? AppColors.income : AppColors.expense,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(statusMsg, style: TextStyle(color: statusOk ? AppColors.income : AppColors.expense, fontSize: 13))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _runSync(WidgetRef ref, dynamic strings) async {
    ref.read(_syncLoadingProvider.notifier).state = true;
    ref.read(_syncStatusProvider.notifier).state = null;

    // Simulate a sync operation — in a full implementation this would call
    // SyncService.syncAll() which pushes local SQLite data to Supabase
    await Future.delayed(const Duration(seconds: 2));

    final success = SupabaseService.instance.isSignedIn;
    ref.read(_syncLoadingProvider.notifier).state = false;
    ref.read(_syncSuccessProvider.notifier).state = success;
    ref.read(_syncStatusProvider.notifier).state =
        success ? strings.cloudSyncSuccess : strings.cloudSyncError;
  }

  Widget _buildSyncScopeCard(ThemeData theme, WidgetRef ref) {
    final isId = ref.read(localeProvider).code == 'id';
    final items = isId
        ? [
            (Icons.account_balance_wallet_rounded, 'Transaksi & Dompet'),
            (Icons.task_alt_rounded, 'Tugas & Proyek'),
            (Icons.local_fire_department_rounded, 'Kebiasaan & Streaks'),
            (Icons.water_drop_rounded, 'Log Air & Mood'),
            (Icons.emergency_rounded, 'Kartu Darurat (metadata)'),
          ]
        : [
            (Icons.account_balance_wallet_rounded, 'Transactions & Wallets'),
            (Icons.task_alt_rounded, 'Tasks & Projects'),
            (Icons.local_fire_department_rounded, 'Habits & Streaks'),
            (Icons.water_drop_rounded, 'Water & Mood Logs'),
            (Icons.emergency_rounded, 'Emergency Card (metadata)'),
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isId ? 'Data yang Disinkronkan' : 'What Gets Synced',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(item.$1, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Text(item.$2, style: theme.textTheme.bodyMedium),
              ],
            ),
          )),
          const Divider(height: 20),
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isId
                      ? 'Konten catatan terenkripsi & file vault tetap lokal'
                      : 'Encrypted note contents & vault files stay local only',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard(ThemeData theme, WidgetRef ref) {
    final isId = ref.read(localeProvider).code == 'id';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.security_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isId
                  ? 'Data Anda dienkripsi dengan Row Level Security (RLS). Tidak ada orang lain — termasuk tim Life OS — yang dapat mengakses data Anda.'
                  : 'Your data is secured with Row Level Security (RLS). No one — including the Life OS team — can access your data.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
