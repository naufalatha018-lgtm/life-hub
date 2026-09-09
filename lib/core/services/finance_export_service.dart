import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/app_database.dart';
import '../utils/currency_formatter.dart';

/// Finance transaction export service.
/// Supports CSV export and sharing. PDF export requires a build-time
/// dependency (pdf package) and is implemented as a placeholder stub here.
class FinanceExportService {
  FinanceExportService._();
  static final FinanceExportService instance = FinanceExportService._();

  // ─────────────────────────────────────────────────────────────────────────
  // CSV Export
  // ─────────────────────────────────────────────────────────────────────────

  /// Exports all transactions visible in the given [year]/[month] as CSV
  /// and opens the share sheet. Pass [month] = null to export all months.
  Future<ExportResult> exportCsv({
    required BuildContext context,
    int? year,
    int? month,
    String language = 'id',
  }) async {
    try {
      final db = await AppDatabase.instance.database;

      String whereClause = '';
      List<dynamic> args = [];

      if (year != null && month != null) {
        whereClause = "WHERE strftime('%Y', date) = ? AND strftime('%m', date) = ?";
        args = [year.toString(), month.toString().padLeft(2, '0')];
      } else if (year != null) {
        whereClause = "WHERE strftime('%Y', date) = ?";
        args = [year.toString()];
      }

      final rows = await db.rawQuery(
        "SELECT t.title, t.amount_cents, t.type, t.category, t.date, t.notes, w.name as wallet_name "
        "FROM finance_transactions t LEFT JOIN wallets w ON t.wallet_id = w.id "
        "$whereClause "
        "ORDER BY t.date DESC",
        args,
      );

      if (rows.isEmpty) {
        return ExportResult.empty();
      }

      final isId = language == 'id';
      final header = isId
          ? 'Judul,Jumlah,Tipe,Kategori,Tanggal,Dompet,Catatan'
          : 'Title,Amount,Type,Category,Date,Wallet,Notes';

      final csvLines = <String>[header];
      for (final row in rows) {
        final amount = CurrencyFormatter.formatCents((row['amount_cents'] as int).abs());
        final type = row['type'] as String;
        csvLines.add([
          _escape(row['title'] as String),
          _escape(amount),
          _escape(isId ? (type == 'income' ? 'Pemasukan' : 'Pengeluaran') : type),
          _escape(row['category'] as String? ?? ''),
          _escape(row['date'] as String? ?? ''),
          _escape(row['wallet_name'] as String? ?? ''),
          _escape(row['notes'] as String? ?? ''),
        ].join(','));
      }

      final csv = csvLines.join('\n');

      final dir = await getApplicationDocumentsDirectory();
      final period = (year != null && month != null)
          ? '${year}_${month.toString().padLeft(2, '0')}'
          : (year?.toString() ?? 'all');
      final file = File('${dir.path}/life_os_finance_$period.csv');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: isId ? 'Laporan Keuangan Life OS' : 'Life OS Finance Report',
      );

      return ExportResult.success(file.path, rows.length);
    } catch (e) {
      return ExportResult.error(e.toString());
    }
  }

  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result model
// ─────────────────────────────────────────────────────────────────────────────

class ExportResult {
  final bool success;
  final bool isEmpty;
  final String? filePath;
  final int? rowCount;
  final String? error;

  const ExportResult._({
    required this.success,
    required this.isEmpty,
    this.filePath,
    this.rowCount,
    this.error,
  });

  factory ExportResult.success(String path, int rows) => ExportResult._(
        success: true,
        isEmpty: false,
        filePath: path,
        rowCount: rows,
      );

  factory ExportResult.empty() => const ExportResult._(
        success: false,
        isEmpty: true,
      );

  factory ExportResult.error(String message) => ExportResult._(
        success: false,
        isEmpty: false,
        error: message,
      );
}
