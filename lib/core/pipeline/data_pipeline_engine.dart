import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../database/finance_dao.dart';
import 'report_isolate_worker.dart';

/// State of the background isolate pipeline.
class PipelineState {
  final bool isRunning;
  final double progress; // 0.0 to 1.0
  final String statusMessage;
  final String? generatedPdfPath;
  final FinancialStatistics? latestStats;
  final String? error;

  const PipelineState({
    this.isRunning = false,
    this.progress = 0.0,
    this.statusMessage = 'Idle',
    this.generatedPdfPath,
    this.latestStats,
    this.error,
  });

  PipelineState copyWith({
    bool? isRunning,
    double? progress,
    String? statusMessage,
    String? generatedPdfPath,
    FinancialStatistics? latestStats,
    String? error,
  }) {
    return PipelineState(
      isRunning: isRunning ?? this.isRunning,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      generatedPdfPath: generatedPdfPath ?? this.generatedPdfPath,
      latestStats: latestStats ?? this.latestStats,
      error: error,
    );
  }
}

/// Enterprise Data Pipeline Engine (Laravel Snappy / Queue Job Parity).
class DataPipelineEngine extends StateNotifier<PipelineState> {
  final FinanceDao _financeDao;

  DataPipelineEngine({
    FinanceDao? financeDao,
  })  : _financeDao = financeDao ?? FinanceDao(),
        super(const PipelineState());

  /// Executes background isolate report generation with real-time progress streaming.
  Future<String?> generateExecutiveReport({
    String title = 'Executive Financial Audit & Risk Report',
    String organization = 'Actividata Enterprise Holdings',
  }) async {
    if (state.isRunning) return null;

    state = state.copyWith(
      isRunning: true,
      progress: 0.05,
      statusMessage: 'Querying local SQLite financial transactions...',
      error: null,
    );

    final receivePort = ReceivePort();
    Isolate? isolate;

    try {
      // Step 1: Query transactions on main thread (or pass query args)
      final rawTransactions = await _financeDao.getAllTransactions();

      // If empty, generate a representative sample for executive preview
      final dataset = rawTransactions.isNotEmpty
          ? rawTransactions
          : _generateDemonstrationDataset();

      state = state.copyWith(
        progress: 0.15,
        statusMessage: 'Spawning dedicated background Dart Isolate...',
      );

      // Step 2: Spawn background isolate worker
      final params = ReportIsolateParams(
        sendPort: receivePort.sendPort,
        rawTransactions: dataset,
        title: title,
        organization: organization,
      );

      isolate = await Isolate.spawn(
        ReportIsolateWorker.entryPoint,
        params,
      );

      // Step 3: Stream progress and listen for result
      final completer = Completer<PipelineReportResult>();

      receivePort.listen((message) {
        if (message is PipelineProgressUpdate) {
          state = state.copyWith(
            progress: message.progress,
            statusMessage: message.statusMessage,
          );
        } else if (message is PipelineReportResult) {
          completer.complete(message);
        } else if (message is String && message.startsWith('ERROR:')) {
          completer.completeError(Exception(message));
        }
      });

      final result = await completer.future;

      // Step 4: Write PDF to disk
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/executive_audit_report_$timestamp.pdf');
      await file.writeAsBytes(result.pdfBytes);

      state = state.copyWith(
        isRunning: false,
        progress: 1.0,
        statusMessage: 'Report completed in ${result.executionDurationMs}ms!',
        generatedPdfPath: file.path,
        latestStats: result.stats,
      );

      return file.path;
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        error: e.toString(),
        statusMessage: 'Isolate execution failed: $e',
      );
      return null;
    } finally {
      receivePort.close();
      isolate?.kill(priority: Isolate.immediate);
    }
  }

  List<Map<String, dynamic>> _generateDemonstrationDataset() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      {
        'id': 'tx_demo_01',
        'title': 'Series-A Capital Investment',
        'amount_cents': 2500000000, // $25,000,000
        'type': 'income',
        'category': 'Investments',
        'timestamp': now - 86400000 * 5,
        'location_name': 'Singapore Financial District',
      },
      {
        'id': 'tx_demo_02',
        'title': 'AWS Cloud Compute & GPU Cluster',
        'amount_cents': 185000000, // $1,850,000
        'type': 'expense',
        'category': 'Utilities & Bills',
        'timestamp': now - 86400000 * 12,
        'location_name': 'us-east-1 North Virginia',
      },
      {
        'id': 'tx_demo_03',
        'title': 'Enterprise SaaS Subscriptions Revenue',
        'amount_cents': 940000000, // $9,400,000
        'type': 'income',
        'category': 'Salary',
        'timestamp': now - 86400000 * 18,
        'location_name': 'Stripe Connect Payout',
      },
      {
        'id': 'tx_demo_04',
        'title': 'Legal Counsel & SOC-2 Compliance Audit',
        'amount_cents': 120000000, // $1,200,000
        'type': 'expense',
        'category': 'Work',
        'timestamp': now - 86400000 * 25,
        'location_name': 'London Office',
      },
    ];
  }
}

// ─────────────────────────────────────────────
// RIVERPOD PROVIDERS
// ─────────────────────────────────────────────

final dataPipelineEngineProvider =
    StateNotifierProvider<DataPipelineEngine, PipelineState>((ref) {
  return DataPipelineEngine();
});
