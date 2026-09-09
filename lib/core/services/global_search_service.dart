import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Search result model
// ─────────────────────────────────────────────────────────────────────────────

enum SearchResultType { transaction, task, note, habit, focus }

@immutable
class SearchResult {
  final SearchResultType type;
  final String id;
  final String title;
  final String? subtitle;
  final DateTime? date;

  const SearchResult({
    required this.type,
    required this.id,
    required this.title,
    this.subtitle,
    this.date,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class GlobalSearchService {
  GlobalSearchService._();
  static final GlobalSearchService instance = GlobalSearchService._();

  /// Returns cross-module search results for [query] across tasks, notes
  /// (titles only — content is encrypted), transactions, and habits.
  Future<List<SearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final db = await AppDatabase.instance.database;
    final q = '%${query.trim().toLowerCase()}%';
    final results = <SearchResult>[];

    try {
      // Tasks
      final tasks = await db.rawQuery(
        "SELECT id, title, description, due_date FROM tasks WHERE LOWER(title) LIKE ? OR LOWER(description) LIKE ? ORDER BY created_at DESC LIMIT 10",
        [q, q],
      );
      for (final t in tasks) {
        results.add(SearchResult(
          type: SearchResultType.task,
          id: t['id'] as String,
          title: t['title'] as String,
          subtitle: t['description'] as String?,
          date: t['due_date'] != null ? DateTime.tryParse(t['due_date'] as String) : null,
        ));
      }
    } catch (_) {}

    try {
      // Secure notes (titles only — content is encrypted)
      final notes = await db.rawQuery(
        "SELECT id, title FROM secure_notes WHERE LOWER(title) LIKE ? AND is_archived = 0 ORDER BY created_at DESC LIMIT 10",
        [q],
      );
      for (final n in notes) {
        results.add(SearchResult(
          type: SearchResultType.note,
          id: n['id'] as String,
          title: n['title'] as String,
          subtitle: null,
        ));
      }
    } catch (_) {}

    try {
      // Finance transactions
      final txns = await db.rawQuery(
        "SELECT id, title, amount_cents, type, date FROM finance_transactions WHERE LOWER(title) LIKE ? OR LOWER(category) LIKE ? ORDER BY date DESC LIMIT 10",
        [q, q],
      );
      for (final t in txns) {
        final amountStr = '${t['type'] == 'income' ? '+' : '-'} Rp ${((t['amount_cents'] as int) / 100).toStringAsFixed(0)}';
        results.add(SearchResult(
          type: SearchResultType.transaction,
          id: t['id'] as String,
          title: t['title'] as String,
          subtitle: amountStr,
          date: t['date'] != null ? DateTime.tryParse(t['date'] as String) : null,
        ));
      }
    } catch (_) {}

    try {
      // Habits
      final habits = await db.rawQuery(
        "SELECT id, title, category FROM habits WHERE LOWER(title) LIKE ? OR LOWER(category) LIKE ? LIMIT 10",
        [q, q],
      );
      for (final h in habits) {
        results.add(SearchResult(
          type: SearchResultType.habit,
          id: h['id'] as String,
          title: h['title'] as String,
          subtitle: h['category'] as String?,
        ));
      }
    } catch (_) {}

    return results;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final globalSearchQueryProvider = StateProvider<String>((ref) => '');

final globalSearchResultsProvider =
    FutureProvider.autoDispose<List<SearchResult>>((ref) async {
  final query = ref.watch(globalSearchQueryProvider);
  if (query.trim().isEmpty) return [];
  await Future.delayed(const Duration(milliseconds: 300)); // debounce
  return GlobalSearchService.instance.search(query);
});
