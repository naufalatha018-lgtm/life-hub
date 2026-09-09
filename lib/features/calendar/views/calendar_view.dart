import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../../../core/widgets/currency_toggle_chip.dart';
import '../../finance/models/finance_transaction.dart';
import '../../finance/views/widgets/add_transaction_dialog.dart';
import '../../tasks/models/task_item.dart';
import '../../tasks/views/widgets/add_task_dialog.dart';
import '../models/calendar_event.dart';
import '../providers/calendar_providers.dart';

class CalendarView extends ConsumerWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(calendarViewModeProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final allEvents = ref.watch(allCalendarEventsProvider);
    final selectedDateEvents = ref.watch(eventsForSelectedDateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGlow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_month_rounded, color: AppColors.primaryLight, size: 20),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Agenda & Calendar',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          const CurrencyToggleChip(),
          const SizedBox(width: 8),
          _buildViewModeSelector(ref, viewMode),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 960;

          if (isWide) {
            // Desktop Split-View
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildNavigationHeader(ref, selectedDate, viewMode),
                        const SizedBox(height: 14),
                        _buildMainCalendarContent(context, ref, viewMode, selectedDate, allEvents),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  color: AppColors.cardBorderSubtle,
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildAgendaSidebar(context, ref, selectedDate, selectedDateEvents),
                  ),
                ),
              ],
            );
          }

          // Mobile / Tablet Vertical Layout
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNavigationHeader(ref, selectedDate, viewMode),
                const SizedBox(height: 14),
                _buildMainCalendarContent(context, ref, viewMode, selectedDate, allEvents),
                const SizedBox(height: 20),
                _buildAgendaSidebar(context, ref, selectedDate, selectedDateEvents),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildViewModeSelector(WidgetRef ref, CalendarViewMode currentMode) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: CalendarViewMode.values.map((mode) {
          final isSelected = mode == currentMode;
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(calendarViewModeProvider.notifier).state = mode;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.85) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                mode.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNavigationHeader(
    WidgetRef ref,
    DateTime selectedDate,
    CalendarViewMode viewMode,
  ) {
    String headerText;
    if (viewMode == CalendarViewMode.month) {
      headerText = DateFormat('MMMM yyyy').format(selectedDate);
    } else if (viewMode == CalendarViewMode.week) {
      final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      headerText =
          '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d, yyyy').format(endOfWeek)}';
    } else {
      headerText = DateFormat('EEEE, MMMM d, yyyy').format(selectedDate);
    }

    return GlassContainer(
      blur: 8,
      backgroundColor: AppColors.surfaceVariant.withOpacity(0.4),
      borderColor: AppColors.cardBorderSubtle,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary),
            onPressed: () => _shiftDate(ref, selectedDate, viewMode, -1),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
            onPressed: () => _shiftDate(ref, selectedDate, viewMode, 1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              headerText,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () {
              final now = DateTime.now();
              ref.read(selectedCalendarDateProvider.notifier).state =
                  DateTime(now.year, now.month, now.day);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              side: const BorderSide(color: AppColors.cardBorderSubtle),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Today', style: TextStyle(fontSize: 12, color: AppColors.primaryLight)),
          ),
        ],
      ),
    );
  }

  void _shiftDate(WidgetRef ref, DateTime current, CalendarViewMode mode, int delta) {
    HapticFeedback.selectionClick();
    DateTime next;
    if (mode == CalendarViewMode.month) {
      next = DateTime(current.year, current.month + delta, current.day.clamp(1, 28));
    } else if (mode == CalendarViewMode.week) {
      next = current.add(Duration(days: 7 * delta));
    } else {
      next = current.add(Duration(days: delta));
    }
    ref.read(selectedCalendarDateProvider.notifier).state = next;
  }

  Widget _buildMainCalendarContent(
    BuildContext context,
    WidgetRef ref,
    CalendarViewMode mode,
    DateTime selectedDate,
    List<CalendarEvent> allEvents,
  ) {
    switch (mode) {
      case CalendarViewMode.month:
        return _buildMonthGrid(ref, selectedDate, allEvents);
      case CalendarViewMode.week:
        return _buildWeekTimeline(context, ref, selectedDate, allEvents);
      case CalendarViewMode.day:
        return _buildDayTimeline(context, ref, selectedDate, allEvents);
    }
  }

  Widget _buildMonthGrid(
    WidgetRef ref,
    DateTime selectedDate,
    List<CalendarEvent> allEvents,
  ) {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    final now = DateTime.now();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return GlassContainer(
      blur: 10,
      backgroundColor: AppColors.surfaceVariant.withOpacity(0.4),
      borderColor: AppColors.cardBorderSubtle,
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Weekday header row
          Row(
            children: weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      day,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Divider(color: AppColors.cardBorderSubtle, height: 1),
          const SizedBox(height: 8),

          // 6-week grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42, // 6 rows of 7 days
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final dayOffset = index - (startingWeekday - 1);
              final cellDate = DateTime(selectedDate.year, selectedDate.month, dayOffset + 1);
              final isCurrentMonth = cellDate.month == selectedDate.month;
              final isToday = cellDate.year == now.year &&
                  cellDate.month == now.month &&
                  cellDate.day == now.day;
              final isSelected = cellDate.year == selectedDate.year &&
                  cellDate.month == selectedDate.month &&
                  cellDate.day == selectedDate.day;

              // Events on this day
              final dayEvents = allEvents.where((e) {
                return e.dateTime.year == cellDate.year &&
                    e.dateTime.month == cellDate.month &&
                    e.dateTime.day == cellDate.day;
              }).toList();

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(selectedCalendarDateProvider.notifier).state = cellDate;
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.85)
                        : (isToday ? AppColors.primaryGlow.withOpacity(0.2) : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.primaryLight.withOpacity(0.6))
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${cellDate.day}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isCurrentMonth ? AppColors.textPrimary : AppColors.textMuted.withOpacity(0.4)),
                          fontSize: 13,
                          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      if (dayEvents.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: dayEvents.take(3).map((e) {
                            return Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.white : e.color,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekTimeline(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    List<CalendarEvent> allEvents,
  ) {
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 7,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 7 : 1,
            childAspectRatio: isWide ? 0.45 : 3.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final dayDate = weekDays[index];
            final isSelected = dayDate.year == selectedDate.year &&
                dayDate.month == selectedDate.month &&
                dayDate.day == selectedDate.day;

            final dayEvents = allEvents.where((e) {
              return e.dateTime.year == dayDate.year &&
                  e.dateTime.month == dayDate.month &&
                  e.dateTime.day == dayDate.day;
            }).toList();

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(selectedCalendarDateProvider.notifier).state = dayDate;
              },
              child: GlassContainer(
                blur: 8,
                backgroundColor: isSelected
                    ? AppColors.primaryGlow.withOpacity(0.35)
                    : AppColors.surfaceVariant.withOpacity(0.4),
                borderColor: isSelected ? AppColors.primary : AppColors.cardBorderSubtle,
                borderRadius: BorderRadius.circular(14),
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('E').format(dayDate),
                          style: TextStyle(
                            color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${dayDate.day}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.cardBorderSubtle, height: 12),
                    Expanded(
                      child: dayEvents.isEmpty
                          ? const Center(
                              child: Text('—', style: TextStyle(color: AppColors.textMuted)),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: dayEvents.take(4).length,
                              separatorBuilder: (_, __) => const SizedBox(height: 4),
                              itemBuilder: (context, i) {
                                final e = dayEvents[i];
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: e.color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: e.color.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    e.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: e.color, fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDayTimeline(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    List<CalendarEvent> allEvents,
  ) {
    final dayEvents = allEvents.where((e) {
      return e.dateTime.year == selectedDate.year &&
          e.dateTime.month == selectedDate.month &&
          e.dateTime.day == selectedDate.day;
    }).toList();

    if (dayEvents.isEmpty) {
      return GlassContainer(
        blur: 10,
        padding: const EdgeInsets.all(32),
        backgroundColor: AppColors.surfaceVariant.withOpacity(0.4),
        borderColor: AppColors.cardBorderSubtle,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Column(
            children: const [
              Icon(Icons.event_available_rounded, size: 48, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text(
                'No Scheduled Events Today',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                'Add tasks or log expenses to populate this schedule stream.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dayEvents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final e = dayEvents[index];
        return _buildEventTile(context, e);
      },
    );
  }

  Widget _buildAgendaSidebar(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    List<CalendarEvent> events,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Agenda',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  DateFormat('EEEE, MMM d').format(selectedDate),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Schedule Task',
                  icon: const Icon(Icons.add_task_rounded, color: AppColors.primaryLight, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AddTaskDialog(),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Log Transaction',
                  icon: const Icon(Icons.receipt_long_rounded, color: AppColors.income, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AddTransactionDialog(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          GlassContainer(
            blur: 8,
            padding: const EdgeInsets.all(24),
            backgroundColor: AppColors.surfaceVariant.withOpacity(0.3),
            borderColor: AppColors.cardBorderSubtle,
            borderRadius: BorderRadius.circular(16),
            child: const Center(
              child: Text(
                'No events or transactions scheduled for this date.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _buildEventTile(context, events[index]);
            },
          ),
      ],
    );
  }

  Widget _buildEventTile(BuildContext context, CalendarEvent event) {
    return GlassContainer(
      blur: 8,
      backgroundColor: AppColors.surfaceVariant.withOpacity(0.4),
      borderColor: AppColors.cardBorderSubtle,
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.all(12),
      onTap: () {
        if (event.isTask && event.originalItem is TaskItem) {
          showDialog(
            context: context,
            builder: (_) => AddTaskDialog(existingTask: event.originalItem as TaskItem),
          );
        } else if (event.isFinance && event.originalItem is FinanceTransaction) {
          showDialog(
            context: context,
            builder: (_) =>
                AddTransactionDialog(existingTransaction: event.originalItem as FinanceTransaction),
          );
        }
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: event.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(event.type.icon, color: event.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (event.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.subtitle!,
                    style: TextStyle(color: event.color.withOpacity(0.85), fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('h:mm a').format(event.dateTime),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
