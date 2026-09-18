import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_color_palette.dart';
import '../../../core/theme/app_executive_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/executive_badge.dart';
import '../../finance/providers/finance_providers.dart';
import '../../habits/providers/habits_provider.dart';
import '../../tasks/providers/tasks_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Proof of Work snapshot model
// ─────────────────────────────────────────────────────────────────────────────

class ProofOfWorkSnapshot {
  final DateTime date;
  final int habitsCompleted;
  final int habitsTotal;
  final int tasksCompleted;
  final int netBalanceCents;
  final int readinessScore;
  final int focusMinutes; // placeholder — wired from focus_provider if needed

  const ProofOfWorkSnapshot({
    required this.date,
    required this.habitsCompleted,
    required this.habitsTotal,
    required this.tasksCompleted,
    required this.netBalanceCents,
    required this.readinessScore,
    required this.focusMinutes,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Proof of Work Card Generator Widget
// ─────────────────────────────────────────────────────────────────────────────

/// Renders an exportable 9:16 performance snapshot card.
///
/// The card is drawn on an off-screen [RepaintBoundary], then captured as a
/// PNG and shared via [share_plus] or saved to the Photos gallery.
class ProofOfWorkCardGenerator extends ConsumerStatefulWidget {
  const ProofOfWorkCardGenerator({super.key});

  @override
  ConsumerState<ProofOfWorkCardGenerator> createState() =>
      _ProofOfWorkCardGeneratorState();
}

class _ProofOfWorkCardGeneratorState
    extends ConsumerState<ProofOfWorkCardGenerator> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isExporting = false;

  Future<void> _exportCard() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    HapticFeedback.mediumImpact();

    try {
      await Future.delayed(const Duration(milliseconds: 80)); // let UI settle
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final xFile = XFile.fromData(
        pngBytes,
        mimeType: 'image/png',
        name: 'proof_of_work_${DateFormat('yyyyMMdd').format(DateTime.now())}.png',
      );

      await Share.shareXFiles([xFile], text: '🏆 My Proof of Work — ${DateFormat('d MMM yyyy').format(DateTime.now())}');
    } catch (e) {
      debugPrint('ProofOfWorkCardGenerator._exportCard: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsNotifierProvider);
    final tasksAsync = ref.watch(tasksNotifierProvider);
    final netBalance = ref.watch(netBalanceCentsProvider);

    final habitsState = habitsAsync.valueOrNull;
    final tasksState = tasksAsync.valueOrNull;

    final snapshot = ProofOfWorkSnapshot(
      date: DateTime.now(),
      habitsCompleted: habitsState?.todayCompletedCount ?? 0,
      habitsTotal: habitsState?.activeCount ?? 0,
      tasksCompleted: tasksState?.where((t) => t.isDone).length ?? 0,
      netBalanceCents: netBalance,
      readinessScore: 0, // Updated async below
      focusMinutes: 0, // Placeholder; wire focus_provider if needed
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview card (the content that gets exported)
        RepaintBoundary(
          key: _repaintKey,
          child: _ProofOfWorkCard(snapshot: snapshot),
        ),
        const SizedBox(height: 16),

        // Export button
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _exportCard,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColorPalette.deepAzure, AppColorPalette.lightIndigo],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColorPalette.azureGlow,
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isExporting)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _isExporting ? 'Exporting…' : 'Export & Share Card',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// The actual card content (9:16 aspect ratio)
// ─────────────────────────────────────────────────────────────────────────────

class _ProofOfWorkCard extends StatelessWidget {
  final ProofOfWorkSnapshot snapshot;

  const _ProofOfWorkCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final isPositiveBalance = snapshot.netBalanceCents >= 0;
    final balanceColor = isPositiveBalance
        ? AppColorPalette.electricEmerald
        : AppColorPalette.crimsonVelvet;

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF060810),
              Color(0xFF0D1526),
              Color(0xFF090A0F),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.zero,
        ),
        child: Stack(
          children: [
            // Background glow — top right
            Positioned(
              right: -80,
              top: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColorPalette.deepAzure.withOpacity(0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Background glow — bottom left
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColorPalette.electricEmerald.withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App brand header
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColorPalette.deepAzure, AppColorPalette.lightIndigo],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LifeOS',
                            style: AppExecutiveTheme.subsectionHeader.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Proof of Work',
                            style: AppExecutiveTheme.functionalCaption.copyWith(
                              color: AppColorPalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ExecutiveBadge(
                        label: DateFormat('d MMM yy').format(snapshot.date),
                        style: ExecutiveBadgeStyle.neutral,
                        isMonospace: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Section: Headline metric
                  Text(
                    'Today\'s Performance',
                    style: AppExecutiveTheme.functionalCaption,
                  ),
                  const SizedBox(height: 10),

                  // Habit completion arc display
                  _ArcMetricRow(
                    label: 'HABITS',
                    numerator: snapshot.habitsCompleted,
                    denominator: snapshot.habitsTotal,
                    color: AppColorPalette.warningAmber,
                    icon: Icons.local_fire_department_rounded,
                  ),
                  const SizedBox(height: 14),

                  _ArcMetricRow(
                    label: 'TASKS DONE',
                    numerator: snapshot.tasksCompleted,
                    denominator: null,
                    color: AppColorPalette.deepAzure,
                    icon: Icons.task_alt_rounded,
                  ),
                  const SizedBox(height: 14),

                  _ArcMetricRow(
                    label: 'FOCUS',
                    numerator: snapshot.focusMinutes,
                    denominator: null,
                    suffix: 'min',
                    color: AppColorPalette.lightIndigo,
                    icon: Icons.timer_rounded,
                  ),

                  const Spacer(),

                  // Financial net balance
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: balanceColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: balanceColor.withOpacity(0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NET BALANCE',
                          style: AppExecutiveTheme.functionalCaption.copyWith(
                            color: balanceColor.withOpacity(0.80),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${isPositiveBalance ? '+' : '-'}${CurrencyFormatter.formatCents(snapshot.netBalanceCents.abs())}',
                          style: GoogleFonts.jetBrainsMono(
                            color: balanceColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Footer watermark
                  Center(
                    child: Text(
                      'actividata.app',
                      style: AppExecutiveTheme.functionalCaption.copyWith(
                        color: AppColorPalette.textDisabled,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Arc metric row
// ─────────────────────────────────────────────────────────────────────────────

class _ArcMetricRow extends StatelessWidget {
  final String label;
  final int numerator;
  final int? denominator;
  final String? suffix;
  final Color color;
  final IconData icon;

  const _ArcMetricRow({
    required this.label,
    required this.numerator,
    required this.color,
    required this.icon,
    this.denominator,
    this.suffix,
  });

  String get _valueStr {
    if (denominator != null) return '$numerator / $denominator';
    if (suffix != null) return '$numerator $suffix';
    return '$numerator';
  }

  double get _fraction {
    if (denominator != null && denominator! > 0) {
      return (numerator / denominator!).clamp(0.0, 1.0);
    }
    return numerator > 0 ? 1.0 : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: AppExecutiveTheme.functionalCaption),
                  Text(
                    _valueStr,
                    style: GoogleFonts.jetBrainsMono(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: _fraction,
                  backgroundColor: color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
