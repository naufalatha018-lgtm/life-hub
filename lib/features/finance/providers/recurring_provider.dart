import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../models/finance_transaction.dart';
import '../models/recurring_transaction.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class RecurringTransactionsState {
  final List<RecurringTransaction> templates;
  const RecurringTransactionsState({required this.templates});

  RecurringTransactionsState copyWith({List<RecurringTransaction>? templates}) =>
      RecurringTransactionsState(templates: templates ?? this.templates);
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class RecurringTransactionsNotifier
    extends AsyncNotifier<RecurringTransactionsState> {
  static const _table = 'recurring_transactions';
  static const _uuid = Uuid();

  @override
  Future<RecurringTransactionsState> build() async {
    final db = await AppDatabase.instance.database;
    await _ensureTable(db);
    final templates = await _fetchAll(db);

    // Auto-post any overdue templates on build (app startup)
    await _postDueTemplates(db, templates);

    final updated = await _fetchAll(db);
    return RecurringTransactionsState(templates: updated);
  }

  Future<void> _ensureTable(dynamic db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_table (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount_cents INTEGER NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        interval TEXT NOT NULL,
        next_due TEXT NOT NULL,
        wallet_id TEXT NOT NULL,
        note TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<List<RecurringTransaction>> _fetchAll(dynamic db) async {
    final rows = await db.query(_table, orderBy: 'next_due ASC');
    return rows.map<RecurringTransaction>(RecurringTransaction.fromMap).toList();
  }

  /// For each due template: create a real FinanceTransaction, advance nextDue.
  Future<void> _postDueTemplates(
      dynamic db, List<RecurringTransaction> templates) async {
    final now = DateTime.now();
    for (final t in templates) {
      if (!t.isDue) continue;
      // Create the real transaction
      final txn = FinanceTransaction(
        id: _uuid.v4(),
        title: t.title,
        amountCents: t.amountCents,
        type: t.type,
        category: t.category,
        timestamp: now,
        note: '[Recurring] ${t.note ?? "Auto-recurring"}',
        createdAt: now,
        updatedAt: now,
      );
      await db.insert('finance_transactions', txn.toMap());

      // Advance nextDue
      final nextDue = t.interval.nextDate(t.nextDue);
      await db.update(
        _table,
        {'next_due': nextDue.toIso8601String()},
        where: 'id = ?',
        whereArgs: [t.id],
      );
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> addTemplate({
    required String title,
    required int amountCents,
    required TransactionType type,
    required String category,
    required RecurrenceInterval interval,
    required DateTime startDate,
    required String walletId,
    String? note,
  }) async {
    final db = await AppDatabase.instance.database;
    final template = RecurringTransaction(
      id: _uuid.v4(),
      title: title,
      amountCents: amountCents,
      type: type,
      category: category,
      interval: interval,
      nextDue: startDate,
      walletId: walletId,
      note: note,
      createdAt: DateTime.now(),
    );
    await db.insert(_table, template.toMap());
    ref.invalidateSelf();
  }

  Future<void> toggleActive(String id, bool isActive) async {
    final db = await AppDatabase.instance.database;
    await db.update(_table, {'is_active': isActive ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
    ref.invalidateSelf();
  }

  Future<void> deleteTemplate(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
    ref.invalidateSelf();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final recurringTransactionsProvider =
    AsyncNotifierProvider<RecurringTransactionsNotifier,
        RecurringTransactionsState>(RecurringTransactionsNotifier.new);
