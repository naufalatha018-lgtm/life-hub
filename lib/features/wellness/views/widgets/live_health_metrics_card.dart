import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_container.dart';
import '../../../../core/services/health_sync_service.dart';
import '../../providers/health_sync_provider.dart';

/// Executive Live Health Metrics Card.
/// Synchronized via Google Health Connect from Redmi Watch 5 Lite / Mi Fitness.
class LiveHealthMetricsCard extends ConsumerWidget {
  const LiveHealthMetricsCard({
    super.key,
    this.showCompact = false,
  });

  final bool showCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthSyncProvider);
    final isId = ref.watch(localeProvider).code == 'id';

    final snapshot = healthAsync.value ?? HealthSnapshot.empty();
    final isLoading = healthAsync.isLoading;

    return GlassContainer(
      backgroundColor: AppColors.surface,
      borderColor: AppColors.cardBorder,
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.watch_rounded,
                  color: Color(0xFF0D9488),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isId ? 'Metrik Kesehatan Langsung' : 'Live Health Metrics',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: snapshot.isConnected
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Redmi Watch 5 Lite • Health Connect',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Sync Action
              IconButton(
                onPressed: isLoading
                    ? null
                    : () => ref.read(healthSyncProvider.notifier).sync(),
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.sync_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                tooltip: isId ? 'Sinkronkan Sekarang' : 'Sync Now',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Metric Grid (2x2)
          Row(
            children: [
              // 1. STEPS
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.directions_walk_rounded,
                  iconColor: const Color(0xFF0284C7),
                  iconBg: const Color(0xFFE0F2FE),
                  label: isId ? 'Langkah' : 'Steps',
                  value: snapshot.steps > 0
                      ? NumberFormat('#,###').format(snapshot.steps)
                      : '0',
                  unit: isId ? 'langkah' : 'steps',
                  progress: (snapshot.steps / 10000.0).clamp(0.0, 1.0),
                  goalText: 'Goal: 10k',
                ),
              ),
              const SizedBox(width: 12),
              // 2. HEART RATE
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.favorite_rounded,
                  iconColor: const Color(0xFFEF4444),
                  iconBg: const Color(0xFFFEF2F2),
                  label: isId ? 'Detak Jantung' : 'Heart Rate',
                  value: snapshot.heartRate != null
                      ? '${snapshot.heartRate}'
                      : '--',
                  unit: 'BPM',
                  subtext: snapshot.heartRate != null
                      ? (isId ? 'Normal Istirahat' : 'Resting Rate')
                      : (isId ? 'Belum ada data' : 'No data'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              // 3. SLEEP
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.bedtime_rounded,
                  iconColor: const Color(0xFF6366F1),
                  iconBg: const Color(0xFFEEF2FF),
                  label: isId ? 'Tidur' : 'Sleep',
                  value: snapshot.sleepDuration > Duration.zero
                      ? snapshot.formattedSleep
                      : '--',
                  unit: '',
                  subtext: snapshot.sleepDuration > Duration.zero
                      ? (isId ? 'Kualitas Baik' : 'Deep & REM')
                      : (isId ? 'Belum ada data' : 'No data'),
                ),
              ),
              const SizedBox(width: 12),
              // 4. ACTIVE CALORIES
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFF97316),
                  iconBg: const Color(0xFFFFF7ED),
                  label: isId ? 'Kalori Aktif' : 'Active Burn',
                  value: snapshot.activeCalories > 0
                      ? '${snapshot.activeCalories.round()}'
                      : '--',
                  unit: 'kcal',
                  subtext: snapshot.activeCalories > 0
                      ? (isId ? 'Pembakaran Hari Ini' : 'Today\'s Burn')
                      : (isId ? 'Belum ada data' : 'No data'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Footer info row
          Row(
            children: [
              Icon(
                snapshot.isConnected
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                color: snapshot.isConnected
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  snapshot.isConnected
                      ? (isId
                          ? 'Tersinkron: ${DateFormat('HH:mm').format(snapshot.lastSyncedAt)}'
                          : 'Synced: ${DateFormat('HH:mm').format(snapshot.lastSyncedAt)}')
                      : (snapshot.errorMessage ??
                          (isId
                              ? 'Izin Health Connect belum diberikan'
                              : 'Health Connect permissions not granted')),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
              if (!snapshot.isConnected)
                TextButton(
                  onPressed: () => ref.read(healthSyncProvider.notifier).requestPermissions(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    isId ? 'Beri Izin' : 'Authorize',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required String unit,
    String? subtext,
    double? progress,
    String? goalText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceHover,
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                minHeight: 4,
              ),
            ),
            if (goalText != null) ...[
              const SizedBox(height: 4),
              Text(
                goalText,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ] else if (subtext != null) ...[
            const SizedBox(height: 4),
            Text(
              subtext,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
