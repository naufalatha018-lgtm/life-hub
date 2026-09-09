import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/location/location_data.dart';
import '../../../../core/location/location_preview_chip.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_container.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/currency_provider.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../models/task_item.dart';
import '../../providers/tasks_providers.dart';

class AddTaskDialog extends ConsumerStatefulWidget {
  const AddTaskDialog({super.key, this.existingTask, this.initialStatus});

  final TaskItem? existingTask;
  final TaskStatus? initialStatus;

  @override
  ConsumerState<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends ConsumerState<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _costController;

  late TaskStatus _status;
  late TaskPriority _priority;
  late String _category;
  DateTime? _dueDate;
  LocationData? _location;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _costController = TextEditingController(
      text: task != null && task.estimatedCostCents > 0
          ? (ref.read(activeCurrencyProvider) == AppCurrency.idr
              ? task.estimatedCostCents.toString()
              : (task.estimatedCostCents / 100.0).toStringAsFixed(2))
          : '',
    );
    _status = task?.status ?? widget.initialStatus ?? TaskStatus.todo;
    _priority = task?.priority ?? TaskPriority.medium;
    _category = task?.category ?? AppConstants.taskCategories.first;
    _dueDate = task?.dueDate;
    _location = task?.location;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _save(AppStrings strings) {
    if (!_formKey.currentState!.validate()) return;

    final activeCurrency = ref.read(activeCurrencyProvider);
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final costCents = CurrencyFormatter.parseToCents(
      _costController.text,
      currency: activeCurrency,
    );

    if (widget.existingTask == null) {
      ref.read(tasksNotifierProvider.notifier).addTask(
            title: title,
            description: desc.isNotEmpty ? desc : null,
            status: _status,
            priority: _priority,
            category: _category,
            dueDate: _dueDate,
            estimatedCostCents: costCents,
            latitude: _location?.latitude,
            longitude: _location?.longitude,
            locationName: _location?.locationName,
          );
    } else {
      ref.read(tasksNotifierProvider.notifier).updateTask(
            widget.existingTask!.copyWith(
              title: title,
              description: desc.isNotEmpty ? desc : null,
              status: _status,
              priority: _priority,
              category: _category,
              dueDate: _dueDate,
              estimatedCostCents: costCents,
              latitude: _location?.latitude,
              longitude: _location?.longitude,
              locationName: _location?.locationName,
            ),
          );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final activeCurrency = ref.watch(activeCurrencyProvider);
    final strings = ref.watch(appStringsProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: GlassContainer(
          blur: 16,
          backgroundColor: AppColors.surface,
          borderColor: AppColors.cardBorder,
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                        child: const Icon(Icons.task_alt_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.existingTask == null ? strings.createTask : strings.editTask,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: strings.taskTitleLabel,
                      hintText: strings.taskTitleHint,
                      prefixIcon: const Icon(Icons.check_box_outlined, color: AppColors.primary),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return strings.taskTitleHint;
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Description
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: strings.descriptionOptional,
                      hintText: '...',
                      prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Priority & Status Row
                  Row(
                    children: [
                      // Priority
                      Expanded(
                        child: DropdownButtonFormField<TaskPriority>(
                          initialValue: _priority,
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: strings.priorityLabel,
                            prefixIcon: const Icon(Icons.flag_rounded, color: AppColors.textMuted),
                          ),
                          items: TaskPriority.values.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(p.label),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _priority = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Status
                      Expanded(
                        child: DropdownButtonFormField<TaskStatus>(
                          initialValue: _status,
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: strings.statusLabel,
                            prefixIcon: const Icon(Icons.low_priority_rounded, color: AppColors.textMuted),
                          ),
                          items: TaskStatus.values.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(s.label),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _status = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Category Selector
                  DropdownButtonFormField<String>(
                    initialValue: AppConstants.taskCategories.contains(_category)
                        ? _category
                        : AppConstants.taskCategories.first,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: strings.categoryLabel,
                      prefixIcon: const Icon(Icons.category_outlined, color: AppColors.textMuted),
                    ),
                    items: AppConstants.taskCategories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Due Date Picker & Estimated Cost
                  Row(
                    children: [
                      // Due Date Button
                      Expanded(
                        child: InkWell(
                          onTap: _pickDueDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textMuted),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _dueDate != null ? DateFormatter.formatShort(_dueDate!) : strings.noDueDate,
                                    style: TextStyle(
                                      color: _dueDate != null ? AppColors.textPrimary : AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Estimated Cost
                      Expanded(
                        child: TextFormField(
                          controller: _costController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: '${strings.estCostLabel} (${activeCurrency.symbol.trim()})',
                            hintText: activeCurrency == AppCurrency.usd ? '0.00' : '50000',
                            prefixIcon: Icon(
                              activeCurrency == AppCurrency.usd ? Icons.attach_money_rounded : Icons.payments_outlined,
                              color: AppColors.income,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Location Tag / Geofence
                  LocationPreviewChip(
                    location: _location,
                    onLocationChanged: (loc) => setState(() => _location = loc),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(strings.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _save(strings),
                          child: Text(widget.existingTask == null ? strings.create : strings.save),
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
}
