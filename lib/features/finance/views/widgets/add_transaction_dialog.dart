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
import '../../models/finance_transaction.dart';
import '../../providers/finance_providers.dart';
import '../../../tasks/providers/tasks_providers.dart';

class AddTransactionDialog extends ConsumerStatefulWidget {
  const AddTransactionDialog({super.key, this.existingTransaction});

  final FinanceTransaction? existingTransaction;

  @override
  ConsumerState<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  late TransactionType _type;
  late String _category;
  late DateTime _timestamp;
  LocationData? _location;
  String? _linkedTaskId;

  @override
  void initState() {
    super.initState();
    final tx = widget.existingTransaction;
    _type = tx?.type ?? TransactionType.expense;
    _titleController = TextEditingController(text: tx?.title ?? '');
    _amountController = TextEditingController(
      text: tx != null
          ? (ref.read(activeCurrencyProvider) == AppCurrency.idr
              ? tx.amountCents.toString()
              : (tx.amountCents / 100.0).toStringAsFixed(2))
          : '',
    );
    _noteController = TextEditingController(text: tx?.note ?? '');
    _category = tx?.category ??
        (_type == TransactionType.income
            ? AppConstants.incomeCategories.first
            : AppConstants.expenseCategories.first);
    _timestamp = tx?.timestamp ?? DateTime.now();
    _location = tx?.location;
    _linkedTaskId = tx?.linkedTaskId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType newType) {
    setState(() {
      _type = newType;
      _category = newType == TransactionType.income
          ? AppConstants.incomeCategories.first
          : AppConstants.expenseCategories.first;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _timestamp,
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
      setState(() {
        _timestamp = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _timestamp.hour,
          _timestamp.minute,
        );
      });
    }
  }

  void _save(AppStrings strings) {
    if (!_formKey.currentState!.validate()) return;

    final activeCurrency = ref.read(activeCurrencyProvider);
    final title = _titleController.text.trim();
    final amountCents = CurrencyFormatter.parseToCents(
      _amountController.text,
      currency: activeCurrency,
    );
    final note = _noteController.text.trim();

    if (amountCents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.amountValidation),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    if (widget.existingTransaction == null) {
      ref.read(financeNotifierProvider.notifier).addTransaction(
            title: title,
            amountCents: amountCents,
            type: _type,
            category: _category,
            timestamp: _timestamp,
            note: note.isNotEmpty ? note : null,
            linkedTaskId: _linkedTaskId,
            latitude: _location?.latitude,
            longitude: _location?.longitude,
            locationName: _location?.locationName,
          );
    } else {
      ref.read(financeNotifierProvider.notifier).updateTransaction(
            widget.existingTransaction!.copyWith(
              title: title,
              amountCents: amountCents,
              type: _type,
              category: _category,
              timestamp: _timestamp,
              note: note.isNotEmpty ? note : null,
              linkedTaskId: _linkedTaskId,
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
    final categories = _type == TransactionType.income
        ? AppConstants.incomeCategories
        : AppConstants.expenseCategories;

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
                          color: (_type == TransactionType.income ? AppColors.income : AppColors.expense)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _type == TransactionType.income ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          color: _type == TransactionType.income ? AppColors.income : AppColors.expense,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.existingTransaction == null ? strings.logTransaction : strings.editTransaction,
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

                  // Income / Expense Toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _onTypeChanged(TransactionType.expense),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _type == TransactionType.expense
                                    ? AppColors.expense
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 16,
                                    color: _type == TransactionType.expense
                                        ? Colors.white
                                        : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    strings.expense,
                                    style: TextStyle(
                                      color: _type == TransactionType.expense
                                          ? Colors.white
                                          : AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _onTypeChanged(TransactionType.income),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _type == TransactionType.income
                                    ? AppColors.income
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 16,
                                    color: _type == TransactionType.income
                                        ? Colors.white
                                        : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    strings.income,
                                    style: TextStyle(
                                      color: _type == TransactionType.income
                                          ? Colors.white
                                          : AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount Field
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: '${strings.amountLabel} (${activeCurrency.symbol.trim()})',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            activeCurrency.symbol,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      hintText: activeCurrency == AppCurrency.usd ? '0.00' : '50000',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return strings.amountValidation;
                      if (CurrencyFormatter.parseToCents(val, currency: activeCurrency) <= 0) {
                        return strings.amountValidation;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Title Field
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: strings.titleLabel,
                      hintText: strings.titleHint,
                      prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.textMuted),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return strings.titleValidation;
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Category Selector
                  DropdownButtonFormField<String>(
                    initialValue: categories.contains(_category) ? _category : categories.first,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: strings.categoryLabel,
                      prefixIcon: const Icon(Icons.label_outline_rounded, color: AppColors.textMuted),
                    ),
                    items: categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(AppConstants.getCategoryIcon(cat), size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(cat),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Date Picker Button
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textMuted),
                              const SizedBox(width: 10),
                              Text(
                                DateFormatter.formatDate(_timestamp),
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Location Tag Chip
                  LocationPreviewChip(
                    location: _location,
                    onLocationChanged: (loc) => setState(() => _location = loc),
                  ),
                  const SizedBox(height: 14),

                  // Linked Task Selector (Cross-Module Linkage)
                  Consumer(
                    builder: (context, ref, child) {
                      final tasks = ref.watch(tasksNotifierProvider).value ?? [];
                      if (tasks.isEmpty) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: DropdownButtonFormField<String?>(
                          initialValue: _linkedTaskId,
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: strings.linkedTaskLabel,
                            prefixIcon: const Icon(Icons.link_rounded, color: AppColors.primary),
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(strings.all == 'Semua' ? 'Tanpa Tautan Tugas' : 'No Linked Task'),
                            ),
                            ...tasks.map(
                              (t) => DropdownMenuItem<String?>(
                                value: t.id,
                                child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                          onChanged: (val) => setState(() => _linkedTaskId = val),
                        ),
                      );
                    },
                  ),

                  // Note Field (Optional)
                  TextFormField(
                    controller: _noteController,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: strings.noteOptional,
                      hintText: '...',
                      prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
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
                          child: Text(widget.existingTransaction == null ? strings.save : strings.update),
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
