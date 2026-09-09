import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../ai/views/ai_assistant_view.dart';
import '../../emergency/views/emergency_card_view.dart';
import '../../finance/providers/finance_providers.dart';
import '../../focus/views/focus_view.dart';
import '../../habits/providers/habits_provider.dart';
import '../../wellness/providers/wellness_provider.dart';
import '../../wellness/views/wellness_view.dart';
import '../../wellness/views/widgets/live_health_metrics_card.dart';
import '../../habits/views/habits_view.dart';

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
    categoryBreakdown: const {}, // simplified; in full impl would query per-category
    language: lang,
  );
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
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0284C7),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF0284C7), Color(0xFF38BDF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      right: -40,
                      top: -40,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 40,
                      top: 60,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
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
                                        _getGreeting(now, lang),
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        strings.dashboardTitle,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // AI Assistant button
                                if (AiService.instance.isAvailable)
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const AiAssistantView()),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF7C3AED), Color(0xFF0284C7)],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF7C3AED).withOpacity(0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    DateFormat('EEE, d MMM').format(now),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Net Worth strip
                            Row(
                              children: [
                                _HeaderPill(
                                  icon: Icons.arrow_upward_rounded,
                                  value: CurrencyFormatter.formatCents(monthlyIncome),
                                  color: AppColors.income,
                                ),
                                const SizedBox(width: 10),
                                _HeaderPill(
                                  icon: Icons.arrow_downward_rounded,
                                  value: CurrencyFormatter.formatCents(monthlyExpense),
                                  color: AppColors.expense,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Net Balance Card ────────────────────────────────────────
                _NetBalanceCard(netBalance: netBalance),
                const SizedBox(height: 16),

                // ── AI Insight Card ─────────────────────────────────────────
                if (AiService.instance.isAvailable)
                  _AiInsightCard(insight: aiInsight, strings: strings),
                if (AiService.instance.isAvailable)
                  const SizedBox(height: 16),

                // ── Finance Summary ─────────────────────────────────────────
                _SectionHeader(title: strings.dashboardFinanceSummary),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: strings.income,
                        value: CurrencyFormatter.formatCents(monthlyIncome),
                        prefix: '',
                        color: AppColors.income,
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        label: strings.totalExpenses,
                        value: CurrencyFormatter.formatCents(monthlyExpense),
                        prefix: '',
                        color: AppColors.expense,
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
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HabitsView())),
                    child: Text(strings.viewAll, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 8),
                habitsAsync.when(
                  loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
                  error: (_, __) => const SizedBox(),
                  data: (state) {
                    if (state.habits.isEmpty) {
                      return _EmptyModuleCard(
                        icon: Icons.local_fire_department_outlined,
                        label: strings.dashboardNoHabits,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HabitsView())),
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
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WellnessView())),
                    child: Text(strings.viewAll, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
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
                  childAspectRatio: 1.6,
                  children: [
                    _QuickModuleCard(
                      icon: Icons.timer_rounded,
                      label: strings.focusTitle,
                      color: AppColors.primary,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FocusView())),
                    ),
                    _QuickModuleCard(
                      icon: Icons.emergency_rounded,
                      label: strings.emergencyCardTitle,
                      color: Colors.red,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmergencyCardView())),
                    ),
                    _QuickModuleCard(
                      icon: Icons.spa_rounded,
                      label: strings.wellnessTitle,
                      color: AppColors.habitMindfulness,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WellnessView())),
                    ),
                    _QuickModuleCard(
                      icon: Icons.local_fire_department_rounded,
                      label: strings.habitsTitle,
                      color: AppColors.streakActive,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HabitsView())),
                    ),
                    if (AiService.instance.isAvailable)
                      _QuickModuleCard(
                        icon: Icons.auto_awesome_rounded,
                        label: strings.aiAssistantTitle,
                        color: const Color(0xFF7C3AED),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiAssistantView())),
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

  String _getGreeting(DateTime now, String lang) {
    if (lang == 'id') {
      if (now.hour < 12) return 'Selamat pagi 🌅';
      if (now.hour < 15) return 'Selamat siang ☀️';
      if (now.hour < 18) return 'Selamat sore 🌆';
      return 'Selamat malam 🌙';
    } else {
      if (now.hour < 12) return 'Good morning 🌅';
      if (now.hour < 15) return 'Good afternoon ☀️';
      if (now.hour < 18) return 'Good evening 🌆';
      return 'Good night 🌙';
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
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
    final color = isPositive ? AppColors.income : AppColors.expense;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isPositive ? Icons.account_balance_wallet_rounded : Icons.warning_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net Balance',
                  style: TextStyle(color: color.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isPositive ? '+' : '-'}${CurrencyFormatter.formatCents(netBalance.abs())}',
                  style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
              ],
            ),
          ),
          Icon(
            isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: color,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1035), Color(0xFF0F2044)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
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
                  gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF0284C7)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                strings.aiInsightTitle,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF7C3AED), size: 12),
            ],
          ),
          const SizedBox(height: 12),
          insight.when(
            loading: () => Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)),
                ),
                const SizedBox(width: 10),
                Text(
                  strings.aiInsightLoading,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
            error: (_, __) => Text(
              strings.aiInsightError,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            data: (text) => Text(
              text ?? strings.aiInsightError,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.5,
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
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
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
    required this.prefix,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final String prefix;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 10,
      backgroundColor: AppColors.surface,
      borderColor: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$prefix$value',
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800),
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

    return GlassContainer(
      blur: 10,
      backgroundColor: AppColors.surface,
      borderColor: AppColors.cardBorder,
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded, color: AppColors.streakActive, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: state.activeCount > 0 ? state.todayCompletedCount / state.activeCount : 0,
                    backgroundColor: AppColors.streakEmpty,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.streakActive),
                    minHeight: 6,
                  ),
                ),
              ],
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
    return GlassContainer(
      blur: 10,
      backgroundColor: AppColors.surface,
      borderColor: AppColors.cardBorder,
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.water_drop_rounded, color: AppColors.waterBlue, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${waterState.todayTotalMl} / ${waterState.dailyGoalMl} ml',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: waterState.progressFraction,
                    backgroundColor: AppColors.waterBlue.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.waterBlue),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (waterState.goalReached) const Text('✅', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Module Card
// ─────────────────────────────────────────────────────────────────────────────

class _QuickModuleCard extends StatelessWidget {
  const _QuickModuleCard({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorderSubtle),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
