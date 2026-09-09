import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../models/habit.dart';
import '../providers/habits_provider.dart';

class HabitsView extends ConsumerWidget {
  const HabitsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsNotifierProvider);
    final strings = ref.watch(appStringsProvider);

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
              child: const Icon(Icons.local_fire_department_rounded, color: AppColors.primaryLight, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              strings.habitsTitle,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            tooltip: strings.addHabit,
            onPressed: () => _showAddHabitDialog(context, ref),
          ),
        ],
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) {
          if (state.habits.isEmpty) {
            return _buildEmptyState(context, ref, strings);
          }
          return _buildHabitList(context, ref, state, strings);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, dynamic strings) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryGlow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.local_fire_department_outlined, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              strings.noHabitsTitle,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              strings.noHabitsSubtitle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddHabitDialog(context, ref),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(strings.addHabit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitList(BuildContext context, WidgetRef ref, HabitsState state, dynamic strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.todayCompletedCount} / ${state.activeCount} ${strings.habitsCompletedToday}',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: state.activeCount > 0 ? state.todayCompletedCount / state.activeCount : 0,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: state.habits.length,
            itemBuilder: (context, i) {
              final habit = state.habits[i];
              return _HabitCard(
                key: ValueKey(habit.id),
                habit: habit,
                isCompletedToday: state.isCompletedToday(habit.id),
                onToggle: () => ref.read(habitsNotifierProvider.notifier).toggleCompletion(habit.id),
                onEdit: () => _showEditHabitDialog(context, ref, habit),
                onDelete: () => _confirmDelete(context, ref, habit),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddHabitDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _HabitFormDialog(),
    );
  }

  void _showEditHabitDialog(BuildContext context, WidgetRef ref, Habit habit) {
    showDialog(
      context: context,
      builder: (_) => _HabitFormDialog(existingHabit: habit),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kebiasaan?'),
        content: Text('Semua riwayat dan streak untuk "${habit.title}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(habitsNotifierProvider.notifier).deleteHabit(habit.id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Habit Card
// ─────────────────────────────────────────────
class _HabitCard extends ConsumerStatefulWidget {
  const _HabitCard({
    super.key,
    required this.habit,
    required this.isCompletedToday,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Habit habit;
  final bool isCompletedToday;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  ConsumerState<_HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<_HabitCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnim = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _categoryColor {
    switch (widget.habit.category) {
      case HabitCategory.health: return AppColors.habitHealth;
      case HabitCategory.productivity: return AppColors.habitProductivity;
      case HabitCategory.mindfulness: return AppColors.habitMindfulness;
      case HabitCategory.finance: return AppColors.habitFinance;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GlassContainer(
          blur: 10,
          backgroundColor: AppColors.surface,
          borderColor: widget.isCompletedToday ? _categoryColor.withOpacity(0.4) : AppColors.cardBorder,
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Category icon + completion circle
              GestureDetector(
                onTap: () async {
                  await _controller.forward();
                  await _controller.reverse();
                  widget.onToggle();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.isCompletedToday ? _categoryColor : _categoryColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: _categoryColor, width: widget.isCompletedToday ? 0 : 2),
                  ),
                  child: Center(
                    child: widget.isCompletedToday
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                        : Text(widget.habit.category.iconAsset, style: const TextStyle(fontSize: 20)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.habit.title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        decoration: widget.isCompletedToday ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _categoryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.habit.frequency.displayNameId,
                            style: TextStyle(color: _categoryColor, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.local_fire_department_rounded, color: AppColors.streakActive, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '${widget.habit.streakCurrent}',
                          style: const TextStyle(color: AppColors.streakActive, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 7-day dot matrix
                    _WeekDotMatrix(habitId: widget.habit.id),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 20),
                color: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == 'edit') widget.onEdit();
                  if (v == 'delete') widget.onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Ubah')),
                  const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: AppColors.expense))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 7-Day Dot Matrix
// ─────────────────────────────────────────────
class _WeekDotMatrix extends ConsumerWidget {
  const _WeekDotMatrix({required this.habitId});
  final String habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsNotifierProvider);
    return habitsAsync.when(
      loading: () => const SizedBox(height: 12),
      error: (_, __) => const SizedBox(height: 12),
      data: (_) => FutureBuilder<List<HabitCompletion>>(
        future: ref.read(habitsNotifierProvider.notifier).getWeekCompletions(habitId),
        builder: (context, snap) {
          final completions = snap.data ?? [];
          final now = DateTime.now();
          return Row(
            children: List.generate(7, (i) {
              final day = now.subtract(Duration(days: 6 - i));
              final dayStart = DateTime(day.year, day.month, day.day);
              final completed = completions.any((c) {
                final cd = DateTime(c.completedDate.year, c.completedDate.month, c.completedDate.day);
                return cd == dayStart;
              });
              final isToday = i == 6;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed ? AppColors.streakActive : AppColors.streakEmpty,
                    border: isToday ? Border.all(color: AppColors.primary, width: 1.5) : null,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Habit Form Dialog (Add/Edit) — StatefulWidget
// to prevent TextEditingController in build()
// ─────────────────────────────────────────────
class _HabitFormDialog extends ConsumerStatefulWidget {
  const _HabitFormDialog({this.existingHabit});
  final Habit? existingHabit;

  @override
  ConsumerState<_HabitFormDialog> createState() => _HabitFormDialogState();
}

class _HabitFormDialogState extends ConsumerState<_HabitFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final FocusNode _titleFocus;
  late HabitFrequency _frequency;
  late HabitCategory _category;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingHabit?.title ?? '');
    _descController = TextEditingController(text: widget.existingHabit?.description ?? '');
    _titleFocus = FocusNode();
    _frequency = widget.existingHabit?.frequency ?? HabitFrequency.daily;
    _category = widget.existingHabit?.category ?? HabitCategory.productivity;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingHabit != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Ubah Kebiasaan' : 'Tambah Kebiasaan Baru',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _titleController,
                    focusNode: _titleFocus,
                    scrollPadding: const EdgeInsets.only(bottom: 140),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nama Kebiasaan',
                      hintText: 'mis. Olahraga 30 menit, Meditasi, dll.',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    scrollPadding: const EdgeInsets.only(bottom: 140),
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi (Opsional)',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  // Frequency
                  const Text('Frekuensi', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: HabitFrequency.values.map((f) {
                      final selected = _frequency == f;
                      return ChoiceChip(
                        label: Text(f.displayNameId),
                        selected: selected,
                        onSelected: (_) => setState(() => _frequency = f),
                        selectedColor: AppColors.primaryGlow,
                        labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textPrimary, fontWeight: selected ? FontWeight.bold : FontWeight.normal),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Category
                  const Text('Kategori', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: HabitCategory.values.map((c) {
                      final selected = _category == c;
                      return ChoiceChip(
                        label: Text('${c.iconAsset} ${c.displayNameId}'),
                        selected: selected,
                        onSelected: (_) => setState(() => _category = c),
                        selectedColor: AppColors.primaryGlow,
                        labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textPrimary, fontWeight: selected ? FontWeight.bold : FontWeight.normal),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          child: Text(isEdit ? 'Simpan' : 'Tambah'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    final notifier = ref.read(habitsNotifierProvider.notifier);
    if (widget.existingHabit != null) {
      await notifier.updateHabit(
        widget.existingHabit!.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          frequency: _frequency,
          category: _category,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      await notifier.addHabit(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        frequency: _frequency,
        category: _category,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }
}
