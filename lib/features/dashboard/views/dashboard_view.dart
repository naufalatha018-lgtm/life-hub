import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/readiness_telemetry_service.dart';
import '../../../core/theme/app_color_palette.dart';
import '../../../core/theme/app_executive_theme.dart';
import '../../../core/theme/premium_glass_card.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/executive_badge.dart';
import '../../ai/views/ai_assistant_view.dart';
import '../../emergency/views/emergency_card_view.dart';
import '../../finance/providers/finance_providers.dart';
import '../../focus/views/focus_view.dart';
import '../../habits/providers/habits_provider.dart';
import '../../habits/views/habits_view.dart';
import '../../wellness/providers/wellness_provider.dart';
import '../../wellness/views/wellness_view.dart';
import '../../wellness/views/widgets/live_health_metrics_card.dart';
import 'proof_of_work_card_generator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AI insight provider
// ─────────────────────────────────────────────────────────────────────────────

final _aiInsightProvider = FutureProvider.autoDispose<String?>((ref) async {
  if (!AiService.instance.isAvailable) return null;

  final monthlyIncome = ref.watch(totalIncomeCentsProvider) / 100;
  final monthlyExpense = ref.watch(totalExpenseCentsProvider) / 100;
  final lang = ref.watch(localeProvider).code;

  return AiService.instance.generateFinancialInsight(
    totalIncome: monthlyIncome,
    totalExpenses: monthlyExpense,
    categoryBreakdown: const {},
    language: lang,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Readiness Telemetry Provider
// ─────────────────────────────────────────────────────────────────────────────

final _readinessScoreProvider = FutureProvider.autoDispose<int>((ref) async {
  // Inject current pending task count for task-load weighting
  final habitsAsync = ref.watch(habitsNotifierProvider);
  final habitsState = habitsAsync.valueOrNull;
  final pendingCount = habitsState != null
      ? habitsState.activeCount - habitsState.todayCompletedCount
      : 0;
  ReadinessTelemetryService.instance.setTaskLoad(pendingCount);
  return ReadinessTelemetryService.instance.computeScore();
});

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard View
// ─────────────────────────────────────────────────────────────────────────────

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final lang = ref.watch(localeProvider).code;
    final habitsAsync = ref.watch(habitsNotifierProvider);
    final waterState = ref.watch(waterNotifierProvider);
    final netBalance = ref.watch(netBalanceCentsProvider);
    final monthlyIncome = ref.watch(totalIncomeCentsProvider);
    final monthlyExpense = ref.watch(totalExpenseCentsProvider);
    final aiInsight = ref.watch(_aiInsightProvider);
    final readinessAsync = ref.watch(_readinessScoreProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColorPalette.surfaceDeepDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Header ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: AppColorPalette.surfaceDeepDark,
            flexibleSpace: FlexibleSpaceBar(
              background: _DashboardHeroHeader(
                now: now,
                monthlyIncome: monthlyIncome,
                monthlyExpense: monthlyExpense,
                strings: strings,
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Daily Readiness Gauge ───────────────────────────────────
                readinessAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (score) => _ReadinessGaugeCard(score: score),
                ),
                const SizedBox(height: 14),

                // ── Net Balance Card ────────────────────────────────────────
                _NetBalanceCard(netBalance: netBalance),
                const SizedBox(height: 14),

                // ── AI Insight Card ─────────────────────────────────────────
                if (AiService.instance.isAvailable) ...[
                  _AiInsightCard(insight: aiInsight, strings: strings),
                  const SizedBox(height: 14),
                ],

                // ── Finance Summary ─────────────────────────────────────────
                _SectionHeader(title: strings.dashboardFinanceSummary),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: strings.income,
                        value: CurrencyFormatter.formatCents(monthlyIncome),
                        color: AppColorPalette.electricEmerald,
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        label: strings.totalExpenses,
                        value: CurrencyFormatter.formatCents(monthlyExpense),
                        color: AppColorPalette.crimsonVelvet,
                        icon: Icons.trending_down_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Habits ──────────────────────────────────────────────────
                _SectionHeader(
                  title: strings.dashboardHabits,
                  action: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HabitsView()),
                    ),
                    child: Text(
                      strings.viewAll,
                      style: AppExecutiveTheme.functionalCaption.copyWith(
                        color: AppColorPalette.azureLight,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                habitsAsync.when(
                  loading: () => const SizedBox(
                    height: 60,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColorPalette.deepAzure,
                      ),
                    ),
                  ),
                  error: (_, __) => const SizedBox(),
                  data: (state) {
                    if (state.habits.isEmpty) {
                      return _EmptyModuleCard(
                        icon: Icons.local_fire_department_outlined,
                        label: strings.dashboardNoHabits,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HabitsView()),
                        ),
                      );
                    }
                    return _HabitsSummaryCard(state: state, lang: lang);
                  },
                ),
                const SizedBox(height: 20),

                // ── Wellness ────────────────────────────────────────────────
                _SectionHeader(
                  title: strings.dashboardWellness,
                  action: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WellnessView()),
                    ),
                    child: Text(
                      strings.viewAll,
                      style: AppExecutiveTheme.functionalCaption.copyWith(
                        color: AppColorPalette.azureLight,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const LiveHealthMetricsCard(),
                const SizedBox(height: 12),
                _WaterSummaryCard(waterState: waterState),
                const SizedBox(height: 20),

                // ── Quick Access Modules ─────────────────────────────────────
                _SectionHeader(title: strings.dashboardModules),
                const SizedBox(height: 8),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.65,
                  children: [
                    _QuickModuleCard(
                      icon: Icons.timer_rounded,
                      label: strings.focusTitle,
                      accentColor: AppColorPalette.deepAzure,
                      badgeStyle: ExecutiveBadgeStyle.azure,
                      badgeLabel: 'FOCUS',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FocusView()),
                      ),
                    ),
                    _QuickModuleCard(
                      icon: Icons.emergency_rounded,
                      label: strings.emergencyCardTitle,
                      accentColor: AppColorPalette.crimsonVelvet,
                      badgeStyle: ExecutiveBadgeStyle.crimson,
                      badgeLabel: 'SOS',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EmergencyCardView()),
                      ),
                    ),
                    _QuickModuleCard(
                      icon: Icons.spa_rounded,
                      label: strings.wellnessTitle,
                      accentColor: AppColorPalette.electricEmerald,
                      badgeStyle: ExecutiveBadgeStyle.emerald,
                      badgeLabel: 'WELLNESS',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WellnessView()),
                      ),
                    ),
                    _QuickModuleCard(
                      icon: Icons.local_fire_department_rounded,
                      label: strings.habitsTitle,
                      accentColor: AppColorPalette.warningAmber,
                      badgeStyle: ExecutiveBadgeStyle.amber,
                      badgeLabel: 'HABITS',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HabitsView()),
                      ),
                    ),
                    if (AiService.instance.isAvailable)
                      _QuickModuleCard(
                        icon: Icons.auto_awesome_rounded,
                        label: strings.aiAssistantTitle,
                        accentColor: AppColorPalette.lightIndigo,
                        badgeStyle: ExecutiveBadgeStyle.neutral,
                        badgeLabel: 'AI',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AiAssistantView()),
                        ),
                      ),
                    _QuickModuleCard(
                      icon: Icons.workspace_premium_rounded,
                      label: 'Proof of Work',
                      accentColor: AppColorPalette.warningAmber,
                      badgeStyle: ExecutiveBadgeStyle.amber,
                      badgeLabel: 'PROOF',
                      onTap: () => _showProofOfWorkSheet(context),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Proof of Work bottom-sheet launcher
// ─────────────────────────────────────────────────────────────────────────────

void _showProofOfWorkSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColorPalette.surfaceDeepDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColorPalette.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColorPalette.warningAmber.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColorPalette.warningAmber,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proof of Work',
                        style: AppExecutiveTheme.subsectionHeader.copyWith(fontSize: 16),
                      ),
                      Text(
                        'Exportable performance snapshot',
                        style: AppExecutiveTheme.functionalCaption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppColorPalette.borderSubtle, height: 24),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: const ProofOfWorkCardGenerator(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Header
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardHeroHeader extends StatelessWidget {
  final DateTime now;
  final int monthlyIncome;
  final int monthlyExpense;
  final dynamic strings;

  const _DashboardHeroHeader({
    required this.now,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorPalette.surfaceDeepDark,
            Color(0xFF0D1526),
            Color(0xFF0A1020),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Decorative radial glow – top right
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColorPalette.deepAzure.withOpacity(0.18),
                    AppColorPalette.deepAzure.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Decorative radial glow – bottom left
          Positioned(
            left: -30,
            bottom: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColorPalette.electricEmerald.withOpacity(0.10),
                    AppColorPalette.electricEmerald.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.dashboardTitle,
                              style: AppExecutiveTheme.sectionHeader.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('EEEE, d MMMM yyyy').format(now),
                              style: AppExecutiveTheme.functionalCaption.copyWith(
                                color: AppColorPalette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (AiService.instance.isAvailable)
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AiAssistantView()),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColorPalette.lightIndigo,
                                  AppColorPalette.deepAzure,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColorPalette.deepAzure.withOpacity(0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Income / Expense strip pills
                  Row(
                    children: [
                      _HeaderPill(
                        icon: Icons.arrow_upward_rounded,
                        value: CurrencyFormatter.formatCents(monthlyIncome),
                        color: AppColorPalette.electricEmerald,
                      ),
                      const SizedBox(width: 10),
                      _HeaderPill(
                        icon: Icons.arrow_downward_rounded,
                        value: CurrencyFormatter.formatCents(monthlyExpense),
                        color: AppColorPalette.crimsonVelvet,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header Pill
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _HeaderPill({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Readiness Gauge Card
// ─────────────────────────────────────────────────────────────────────────────

class _ReadinessGaugeCard extends StatelessWidget {
  final int score;
  const _ReadinessGaugeCard({required this.score});

  Color get _scoreColor {
    if (score >= 80) return AppColorPalette.electricEmerald;
    if (score >= 55) return AppColorPalette.warningAmber;
    return AppColorPalette.crimsonVelvet;
  }

  String get _scoreLabel {
    if (score >= 80) return 'PEAK';
    if (score >= 55) return 'MODERATE';
    return 'LOW';
  }

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      backgroundColor: AppColorPalette.surfaceSecondary.withOpacity(0.60),
      child: Row(
        children: [
          // Radial Gauge Arc
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _RadialGaugePainter(
                fraction: score / 100.0,
                color: _scoreColor,
                trackColor: AppColorPalette.borderSubtle,
              ),
              child: Center(
                child: Text(
                  '$score',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _scoreColor,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Daily Readiness',
                      style: AppExecutiveTheme.subsectionHeader.copyWith(fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                    ExecutiveBadge(
                      label: _scoreLabel,
                      style: score >= 80
                          ? ExecutiveBadgeStyle.emerald
                          : score >= 55
                              ? ExecutiveBadgeStyle.amber
                              : ExecutiveBadgeStyle.crimson,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Sleep · Heart Rate · Task Load',
                  style: AppExecutiveTheme.functionalCaption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Radial Gauge Painter
class _RadialGaugePainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color trackColor;
  const _RadialGaugePainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    if (fraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * fraction.clamp(0.0, 1.0),
        false,
        valuePaint,
      );
    }

    // Glow layer
    if (fraction > 0) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * fraction.clamp(0.0, 1.0),
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RadialGaugePainter old) =>
      old.fraction != fraction || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Net Balance Card
// ─────────────────────────────────────────────────────────────────────────────

class _NetBalanceCard extends StatelessWidget {
  final int netBalance;
  const _NetBalanceCard({required this.netBalance});

  @override
  Widget build(BuildContext context) {
    final isPositive = netBalance >= 0;
    final accent = isPositive ? AppColorPalette.electricEmerald : AppColorPalette.crimsonVelvet;
    final dimColor = isPositive ? AppColorPalette.emeraldDim : AppColorPalette.crimsonDim;

    return PremiumGlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      backgroundColor: dimColor.withOpacity(0.35),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withOpacity(0.35),
          accent.withOpacity(0.10),
        ],
      ),
      customShadows: [
        BoxShadow(
          color: accent.withOpacity(0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.30)),
            ),
            child: Icon(
              isPositive
                  ? Icons.account_balance_wallet_rounded
                  : Icons.warning_rounded,
              color: accent,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NET BALANCE',
                  style: AppExecutiveTheme.functionalCaption.copyWith(
                    color: accent.withOpacity(0.80),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${isPositive ? '+' : '-'}${CurrencyFormatter.formatCents(netBalance.abs())}',
                    style: GoogleFonts.jetBrainsMono(
                      color: accent,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: accent,
            size: 28,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Insight Card
// ─────────────────────────────────────────────────────────────────────────────

class _AiInsightCard extends StatelessWidget {
  final AsyncValue<String?> insight;
  final dynamic strings;
  const _AiInsightCard({required this.insight, required this.strings});

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      backgroundColor: AppColorPalette.indigoDim.withOpacity(0.40),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColorPalette.lightIndigo.withOpacity(0.35),
          AppColorPalette.deepAzure.withOpacity(0.15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColorPalette.lightIndigo, AppColorPalette.deepAzure],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                strings.aiInsightTitle,
                style: AppExecutiveTheme.subsectionHeader.copyWith(fontSize: 14),
              ),
              const Spacer(),
              const ExecutiveBadge(label: 'AI', style: ExecutiveBadgeStyle.neutral),
            ],
          ),
          const SizedBox(height: 12),
          insight.when(
            loading: () => Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColorPalette.lightIndigo,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  strings.aiInsightLoading,
                  style: AppExecutiveTheme.bodyText,
                ),
              ],
            ),
            error: (_, __) => Text(
              strings.aiInsightError,
              style: AppExecutiveTheme.bodyText,
            ),
            data: (text) => Text(
              text ?? strings.aiInsightError,
              style: AppExecutiveTheme.bodyText.copyWith(
                color: AppColorPalette.textSecondary,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppExecutiveTheme.subsectionHeader,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ?action,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metric Card
// ─────────────────────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      backgroundColor: color.withOpacity(0.07),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withOpacity(0.30), color.withOpacity(0.08)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppExecutiveTheme.functionalCaption,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Habits Summary Card
// ─────────────────────────────────────────────────────────────────────────────

class _HabitsSummaryCard extends StatelessWidget {
  const _HabitsSummaryCard({required this.state, required this.lang});
  final HabitsState state;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final label = lang == 'id'
        ? '${state.todayCompletedCount} / ${state.activeCount} kebiasaan selesai hari ini'
        : '${state.todayCompletedCount} / ${state.activeCount} habits done today';
    final progress =
        state.activeCount > 0 ? state.todayCompletedCount / state.activeCount : 0.0;

    return PremiumGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      backgroundColor: AppColorPalette.surfaceSecondary.withOpacity(0.60),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColorPalette.warningAmber.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppColorPalette.warningAmber,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppExecutiveTheme.bodyMedium.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColorPalette.borderSubtle,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColorPalette.warningAmber,
                    ),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(progress * 100).round()}%',
            style: GoogleFonts.jetBrainsMono(
              color: AppColorPalette.warningAmber,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Water Summary Card
// ─────────────────────────────────────────────────────────────────────────────

class _WaterSummaryCard extends StatelessWidget {
  const _WaterSummaryCard({required this.waterState});
  final WaterState waterState;

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      backgroundColor: AppColorPalette.surfaceSecondary.withOpacity(0.60),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              color: Color(0xFF38BDF8),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hydration',
                  style: AppExecutiveTheme.functionalCaption,
                ),
                const SizedBox(height: 4),
                Text(
                  '${waterState.todayTotalMl} / ${waterState.dailyGoalMl} ml',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColorPalette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: waterState.progressFraction,
                    backgroundColor: AppColorPalette.borderSubtle,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          if (waterState.goalReached) ...[
            const SizedBox(width: 10),
            const ExecutiveBadge(
              label: 'GOAL',
              style: ExecutiveBadgeStyle.emerald,
              icon: Icons.check_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Module Card
// ─────────────────────────────────────────────────────────────────────────────

class _QuickModuleCard extends StatelessWidget {
  const _QuickModuleCard({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.badgeStyle,
    required this.badgeLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final ExecutiveBadgeStyle badgeStyle;
  final String badgeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: BorderRadius.circular(16),
      backgroundColor: accentColor.withOpacity(0.07),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accentColor.withOpacity(0.28), accentColor.withOpacity(0.06)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 22),
              const Spacer(),
              ExecutiveBadge(label: badgeLabel, style: badgeStyle),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: AppExecutiveTheme.bodyMedium.copyWith(
              color: AppColorPalette.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty Module Card
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyModuleCard extends StatelessWidget {
  const _EmptyModuleCard({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(14),
      backgroundColor: AppColorPalette.surfaceSecondary.withOpacity(0.40),
      child: Row(
        children: [
          Icon(icon, color: AppColorPalette.textMuted, size: 20),
          const SizedBox(width: 10),
          Text(label, style: AppExecutiveTheme.bodyText),
        ],
      ),
    );
  }
}


