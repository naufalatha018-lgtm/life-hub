import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/audit/audit_log_model.dart';
import '../../../../core/audit/audit_trail_manager.dart';
import '../../../../core/pipeline/data_pipeline_engine.dart';
import '../../../../core/policy/gate.dart';
import '../../../../core/policy/gate_guard.dart';
import '../../../../core/policy/policy_models.dart';
import '../../../../core/sync/offline_sync_engine.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_executive_theme.dart';
import '../../../../core/theme/premium_glass_card.dart';
import '../../../../core/widgets/executive_badge.dart';
import '../../../../core/widgets/executive_button.dart';

/// Ultra-Premium FinTech Executive Controls & Architecture HUD.
///
/// Provides live monitoring and interactive control for:
/// 1. Offline Sync Engine & Persistent Outbox Queue (FIFO draining)
/// 2. Cryptographic HMAC-SHA256 Audit Trail & Tamper Verification
/// 3. Granular RBAC, Gate Policies & Biometric Challenges
/// 4. Background Isolate Report Pipeline & Statistical Modeling
class SettingsExecutiveView extends ConsumerStatefulWidget {
  const SettingsExecutiveView({super.key});

  @override
  ConsumerState<SettingsExecutiveView> createState() => _SettingsExecutiveViewState();
}

class _SettingsExecutiveViewState extends ConsumerState<SettingsExecutiveView> {
  AuditVerificationResult? _lastVerificationResult;
  bool _isVerifyingChain = false;

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(offlineSyncEngineProvider);
    final currentRole = ref.watch(userPermissionProfileProvider);
    final pipelineState = ref.watch(dataPipelineEngineProvider);

    return Scaffold(
      backgroundColor: AppColorPalette.surfaceDeepDark,
      appBar: AppBar(
        backgroundColor: AppColorPalette.surfaceDeepDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColorPalette.textPrimary, size: 18),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_rounded, color: AppColorPalette.deepAzure, size: 18),
                const SizedBox(width: 8),
                Text(
                  'EXECUTIVE CONTROLS',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: AppColorPalette.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              'Laravel Core Parity • Enterprise System Architecture',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColorPalette.textMuted,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        children: [
          // ── 1. Live Sync Status HUD ─────────────────────────────────────────
          _buildSectionTitle('OFFLINE-FIRST SYNC ENGINE (OUTBOX PATTERN)', Icons.sync_rounded),
          const SizedBox(height: 10),
          _buildOutboxHud(syncState),

          const SizedBox(height: 24),

          // ── 2. Cryptographic Audit Trail Inspector ─────────────────────────
          _buildSectionTitle('IMMUTABLE AUDIT TRAIL (HMAC-SHA256 CHAIN)', Icons.verified_user_rounded),
          const SizedBox(height: 10),
          _buildAuditTrailCard(),

          const SizedBox(height: 24),

          // ── 3. RBAC Policy & Gate Engine ───────────────────────────────────
          _buildSectionTitle('POLICY ENGINE & GRANULAR RBAC GATES', Icons.policy_rounded),
          const SizedBox(height: 10),
          _buildPolicyEngineCard(currentRole),

          const SizedBox(height: 24),

          // ── 4. Background Isolate Report Pipeline ──────────────────────────
          _buildSectionTitle('BACKGROUND ISOLATE REPORT PIPELINE', Icons.analytics_rounded),
          const SizedBox(height: 10),
          _buildIsolatePipelineCard(pipelineState),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColorPalette.azureLight),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppExecutiveTheme.functionalCaption.copyWith(
            color: AppColorPalette.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── Outbox Queue HUD ───────────────────────────────────────────────────────
  Widget _buildOutboxHud(SyncEngineState syncState) {
    final hasPending = syncState.pendingCount > 0;

    return PremiumGlassCard(
      blurSigma: 16,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: syncState.isSyncing
                          ? AppColorPalette.warningAmber
                          : (hasPending ? AppColorPalette.azureLight : AppColorPalette.electricEmerald),
                      boxShadow: [
                        BoxShadow(
                          color: (syncState.isSyncing
                                  ? AppColorPalette.warningAmber
                                  : AppColorPalette.electricEmerald)
                              .withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    syncState.isSyncing
                        ? 'DRAINING OUTBOX QUEUE...'
                        : (hasPending ? 'OUTBOX MUTATIONS PENDING' : 'ALL SYSTEMS SYNCHRONIZED'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: AppColorPalette.textPrimary,
                    ),
                  ),
                ],
              ),
              ExecutiveBadge(
                label: syncState.isSyncing
                    ? 'IN-TRANSIT'
                    : (hasPending ? '${syncState.pendingCount} QUEUED' : 'IN-SYNC'),
                style: syncState.isSyncing
                    ? ExecutiveBadgeStyle.amber
                    : (hasPending ? ExecutiveBadgeStyle.azure : ExecutiveBadgeStyle.emerald),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'PENDING QUEUE',
                  value: '${syncState.pendingCount}',
                  unit: 'items',
                  color: hasPending ? AppColorPalette.warningAmber : AppColorPalette.electricEmerald,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'TOTAL SYNCED',
                  value: '${syncState.totalSyncedSinceStartup}',
                  unit: 'mutations',
                  color: AppColorPalette.azureLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                syncState.lastSyncTime != null
                    ? 'Last synced: ${syncState.lastSyncTime!.hour.toString().padLeft(2, '0')}:${syncState.lastSyncTime!.minute.toString().padLeft(2, '0')}:${syncState.lastSyncTime!.second.toString().padLeft(2, '0')}'
                    : 'Awaiting sync dispatch',
                style: GoogleFonts.inter(fontSize: 11, color: AppColorPalette.textMuted),
              ),
              ExecutiveButton(
                label: 'Flush Outbox',
                icon: Icons.bolt_rounded,
                height: 38,
                variant: ExecutiveButtonVariant.electricEmerald,
                isLoading: syncState.isSyncing,
                onPressed: () async {
                  final processed = await ref.read(offlineSyncEngineProvider.notifier).flushQueue();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Outbox drained successfully ($processed items processed).')),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Cryptographic Audit Trail Card ─────────────────────────────────────────
  Widget _buildAuditTrailCard() {
    final recentLogsAsync = ref.watch(recentAuditLogsProvider);

    return PremiumGlassCard(
      blurSigma: 16,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tamper-Evident Ledger',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColorPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'HMAC-SHA256 Sequential Cryptographic Chaining',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColorPalette.textMuted),
                  ),
                ],
              ),
              ExecutiveButton(
                label: 'Verify Chain',
                icon: Icons.fingerprint_rounded,
                height: 36,
                variant: ExecutiveButtonVariant.glassOutline,
                isLoading: _isVerifyingChain,
                onPressed: _runChainVerification,
              ),
            ],
          ),

          // Verification Banner
          if (_lastVerificationResult != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _lastVerificationResult!.isValid
                    ? AppColorPalette.emeraldDim.withOpacity(0.40)
                    : AppColorPalette.crimsonDim.withOpacity(0.40),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _lastVerificationResult!.isValid
                      ? AppColorPalette.electricEmerald.withOpacity(0.40)
                      : AppColorPalette.crimsonVelvet.withOpacity(0.40),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _lastVerificationResult!.isValid
                        ? Icons.verified_rounded
                        : Icons.gpp_bad_rounded,
                    color: _lastVerificationResult!.isValid
                        ? AppColorPalette.electricEmerald
                        : AppColorPalette.crimsonVelvet,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _lastVerificationResult!.isValid
                          ? 'HMAC CHAIN INTEGRITY VALID: ${_lastVerificationResult!.verifiedCount} nodes verified. 0 tampering detected.'
                          : 'TAMPER ALERT: ${_lastVerificationResult!.reason}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _lastVerificationResult!.isValid
                            ? AppColorPalette.electricEmerald
                            : AppColorPalette.crimsonVelvet,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          Text('RECENT AUDIT LOGS (BLOCKS)', style: AppExecutiveTheme.functionalCaption),
          const SizedBox(height: 8),

          recentLogsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColorPalette.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.history_toggle_off_rounded, color: AppColorPalette.textMuted, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        'No audit blocks yet. Mutate a transaction or generate a report to write blocks.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 11.5, color: AppColorPalette.textMuted),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: logs.take(4).map((entry) => _buildAuditEntryRow(entry)).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColorPalette.deepAzure, strokeWidth: 2),
              ),
            ),
            error: (err, _) => Text('Failed to load audit logs: $err', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditEntryRow(AuditLogEntry entry) {
    final shortHash = entry.currentHash.length > 12
        ? '${entry.currentHash.substring(0, 6)}...${entry.currentHash.substring(entry.currentHash.length - 6)}'
        : entry.currentHash;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColorPalette.surfaceElevated.withOpacity(0.60),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColorPalette.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColorPalette.surfaceInteractive,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              entry.actionType == 'CREATE'
                  ? Icons.add_circle_outline_rounded
                  : (entry.actionType == 'DELETE' ? Icons.delete_outline_rounded : Icons.edit_note_rounded),
              size: 16,
              color: entry.actionType == 'CREATE'
                  ? AppColorPalette.electricEmerald
                  : (entry.actionType == 'DELETE' ? AppColorPalette.crimsonVelvet : AppColorPalette.azureLight),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${entry.actionType} ${entry.tableName}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColorPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '#${entry.logId.substring(0, 8)}',
                      style: AppExecutiveTheme.cryptoMono.copyWith(fontSize: 10, color: AppColorPalette.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Hash: $shortHash • Actor: ${entry.actorId}',
                  style: AppExecutiveTheme.cryptoMono.copyWith(fontSize: 10, color: AppColorPalette.electricEmerald),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded, size: 14, color: AppColorPalette.electricEmerald),
        ],
      ),
    );
  }

  // ── Policy Engine & Granular RBAC Card ─────────────────────────────────────
  Widget _buildPolicyEngineCard(UserPermissionProfile currentProfile) {
    return PremiumGlassCard(
      blurSigma: 16,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Client-Side RBAC & Gates',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColorPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Active Role: ${currentProfile.role.name.toUpperCase()}',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColorPalette.textMuted),
                  ),
                ],
              ),
              ExecutiveBadge(
                label: currentProfile.role.name.toUpperCase(),
                style: currentProfile.isExecutive
                    ? ExecutiveBadgeStyle.emerald
                    : ExecutiveBadgeStyle.azure,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('SWITCH TEST ROLE', style: AppExecutiveTheme.functionalCaption),
          const SizedBox(height: 8),

          // Role switcher buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: UserRole.values.map((role) {
              final isSelected = currentProfile.role == role;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(userPermissionProfileProvider.notifier).state = UserPermissionProfile(
                    userId: 'user_${role.name}',
                    email: '${role.name}@lifehub.enterprise',
                    role: role,
                    directPermissions: role == UserRole.executive
                        ? {'view-ledger', 'export-high-value-report', 'purge-audit-trail'}
                        : (role == UserRole.auditor ? {'view-audit-trail', 'verify-audit-chain'} : {}),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColorPalette.deepAzure : AppColorPalette.surfaceInteractive,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColorPalette.azureLight : AppColorPalette.borderSubtle,
                    ),
                  ),
                  child: Text(
                    role.name.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColorPalette.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),
          Text('GATE TEST: EXPORT HIGH-VALUE AUDIT REPORT', style: AppExecutiveTheme.functionalCaption),
          const SizedBox(height: 8),

          // GateGuard wrapped demonstration
          GateGuard(
            ability: 'export-high-value-report',
            fallback: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColorPalette.crimsonDim.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColorPalette.crimsonVelvet.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, color: AppColorPalette.crimsonVelvet, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gate Denied: Switch to EXECUTIVE role to unlock high-value report exports.',
                      style: GoogleFonts.inter(fontSize: 11.5, color: AppColorPalette.crimsonVelvet),
                    ),
                  ),
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColorPalette.emeraldDim.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColorPalette.electricEmerald.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColorPalette.electricEmerald, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Gate Allowed: Executive role authorized with biometric challenges.',
                            style: GoogleFonts.inter(fontSize: 11.5, color: AppColorPalette.electricEmerald),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ExecutiveButton(
                    label: 'Challenge',
                    icon: Icons.fingerprint_rounded,
                    height: 32,
                    variant: ExecutiveButtonVariant.glassOutline,
                    onPressed: () async {
                      final authorized = await Gate.authorize(
                        context: context,
                        user: currentProfile,
                        ability: 'export-high-value-report',
                        requireBiometric: true,
                        biometricReason: 'Verifikasi identitas eksekutif untuk ekspor laporan berisiko tinggi',
                      );
                      if (authorized && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Otorisasi Biometrik Berhasil! Akses Diberikan.'),
                            backgroundColor: Color(0xFF00E599),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Background Isolate Report Pipeline Card ────────────────────────────────
  Widget _buildIsolatePipelineCard(PipelineState pipelineState) {
    return PremiumGlassCard(
      blurSigma: 16,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Multi-Threaded Isolate Engine',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColorPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Zero UI-thread blocking • PDF & Variance Modeling',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColorPalette.textMuted),
                  ),
                ],
              ),
              ExecutiveButton(
                label: 'Compile Report',
                icon: Icons.play_arrow_rounded,
                height: 36,
                variant: ExecutiveButtonVariant.primaryBrand,
                isLoading: pipelineState.isRunning,
                onPressed: () async {
                  final path = await ref
                      .read(dataPipelineEngineProvider.notifier)
                      .generateExecutiveReport();

                  // Record in audit trail
                  if (path != null) {
                    await ref.read(auditTrailManagerProvider).recordOperation(
                          actorId: ref.read(userPermissionProfileProvider).email,
                          actionType: 'CREATE',
                          tableName: 'executive_pdf_reports',
                          after: {'path': path, 'timestamp': DateTime.now().millisecondsSinceEpoch},
                        );
                    ref.invalidate(recentAuditLogsProvider);
                  }
                },
              ),
            ],
          ),

          // Real-time animated progress bar
          if (pipelineState.isRunning || pipelineState.progress > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pipelineState.progress,
                minHeight: 8,
                backgroundColor: AppColorPalette.surfaceInteractive,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColorPalette.electricEmerald),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pipelineState.statusMessage,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColorPalette.textSecondary),
                ),
                Text(
                  '${(pipelineState.progress * 100).toInt()}%',
                  style: AppExecutiveTheme.cryptoMono.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],

          // Statistical Preview Banner
          if (pipelineState.latestStats != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColorPalette.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColorPalette.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('COMPUTED STATISTICAL DISTRIBUTIONS', style: AppExecutiveTheme.functionalCaption),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          label: 'RUNWAY EST.',
                          value: '${pipelineState.latestStats!.runwayMonths.toStringAsFixed(1)}',
                          unit: 'months',
                          color: AppColorPalette.electricEmerald,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          label: 'STD DEVIATION',
                          value: '\$${pipelineState.latestStats!.standardDeviation.toStringAsFixed(0)}',
                          unit: 'volatility',
                          color: AppColorPalette.warningAmber,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          label: 'MONTHLY BURN',
                          value: '\$${pipelineState.latestStats!.monthlyBurnRate.toStringAsFixed(0)}',
                          unit: '/mo',
                          color: AppColorPalette.crimsonVelvet,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Open PDF action if completed
          if (pipelineState.generatedPdfPath != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ExecutiveButton(
                    label: 'Open Executive PDF',
                    icon: Icons.picture_as_pdf_rounded,
                    height: 42,
                    variant: ExecutiveButtonVariant.glassOutline,
                    onPressed: () async {
                      final file = File(pipelineState.generatedPdfPath!);
                      if (await file.exists()) {
                        await OpenFile.open(file.path);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ExecutiveButton(
                    label: 'Share PDF File',
                    icon: Icons.share_rounded,
                    height: 42,
                    variant: ExecutiveButtonVariant.primaryBrand,
                    onPressed: () async {
                      final file = File(pipelineState.generatedPdfPath!);
                      if (await file.exists()) {
                        await Share.shareXFiles(
                          [XFile(file.path, mimeType: 'application/pdf')],
                          subject: 'Executive Financial Audit Report',
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColorPalette.surfaceElevated.withOpacity(0.50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColorPalette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 9.5, color: AppColorPalette.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(width: 3),
              Text(unit, style: GoogleFonts.inter(fontSize: 9.5, color: AppColorPalette.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _runChainVerification() async {
    setState(() {
      _isVerifyingChain = true;
    });

    try {
      final manager = ref.read(auditTrailManagerProvider);
      final result = await manager.verifyChainIntegrity();

      setState(() {
        _lastVerificationResult = result;
      });

      if (mounted) {
        HapticFeedback.heavyImpact();
      }
    } finally {
      setState(() {
        _isVerifyingChain = false;
      });
    }
  }
}
