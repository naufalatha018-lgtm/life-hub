import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ForexRateData {
  final double rate;
  final double previousRate;
  final DateTime lastUpdated;
  final bool isLive;

  const ForexRateData({
    required this.rate,
    required this.previousRate,
    required this.lastUpdated,
    required this.isLive,
  });

  double get changeDelta => previousRate > 0 ? rate - previousRate : 0.0;
  double get changePercentage =>
      previousRate > 0 ? ((rate - previousRate) / previousRate) * 100 : 0.0;
  double get deltaPercent => changePercentage;

  Map<String, dynamic> toMap() {
    return {
      'rate': rate,
      'previous_rate': previousRate,
      'last_updated': lastUpdated.millisecondsSinceEpoch,
      'is_live': isLive,
    };
  }

  factory ForexRateData.fromMap(Map<String, dynamic> map) {
    return ForexRateData(
      rate: (map['rate'] as num).toDouble(),
      previousRate: (map['previous_rate'] as num?)?.toDouble() ?? (map['rate'] as num).toDouble(),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch((map['last_updated'] as num).toInt()),
      isLive: map['is_live'] as bool? ?? false,
    );
  }
}

class ForexService {
  final FlutterSecureStorage _storage;
  final http.Client _client;

  static const String _cachedRateKey = 'forex_usd_idr_rate';
  static const String _cachedPrevRateKey = 'forex_usd_idr_prev_rate';
  static const String _cachedTimestampKey = 'forex_usd_idr_timestamp';
  static const double defaultRate = 16000.0;

  ForexService({
    FlutterSecureStorage? storage,
    http.Client? client,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  /// Loads last known exchange rate from secure cache, falling back to default 16,000.
  Future<ForexRateData> loadCachedRate() async {
    try {
      final rateStr = await _storage.read(key: _cachedRateKey);
      final prevStr = await _storage.read(key: _cachedPrevRateKey);
      final timeStr = await _storage.read(key: _cachedTimestampKey);

      final rate = double.tryParse(rateStr ?? '') ?? defaultRate;
      final prevRate = double.tryParse(prevStr ?? '') ?? rate;
      final timestamp = timeStr != null
          ? DateTime.fromMillisecondsSinceEpoch(int.tryParse(timeStr) ?? 0)
          : DateTime.now();

      return ForexRateData(
        rate: rate,
        previousRate: prevRate,
        lastUpdated: timestamp,
        isLive: false,
      );
    } catch (_) {
      return ForexRateData(
        rate: defaultRate,
        previousRate: defaultRate,
        lastUpdated: DateTime.now(),
        isLive: false,
      );
    }
  }

  /// Fetches live exchange rate from open forex API.
  /// Falls back gracefully to cached rate if offline, timed out, or API fails.
  Future<ForexRateData> fetchLiveRate() async {
    final cached = await loadCachedRate();

    try {
      // Free public Open Exchange Rates endpoint
      final uri = Uri.parse('https://open.er-api.com/v6/latest/USD');
      final response = await _client.get(uri).timeout(
            const Duration(seconds: 5),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['rates'] is Map) {
          final rates = data['rates'] as Map<String, dynamic>;
          final idrRaw = rates['IDR'];

          if (idrRaw != null) {
            final liveRate = (idrRaw is num) ? idrRaw.toDouble() : double.parse(idrRaw.toString());
            final now = DateTime.now();

            // Cache new rate and preserve previous rate for delta calculations
            await _storage.write(key: _cachedPrevRateKey, value: cached.rate.toString());
            await _storage.write(key: _cachedRateKey, value: liveRate.toString());
            await _storage.write(
              key: _cachedTimestampKey,
              value: now.millisecondsSinceEpoch.toString(),
            );

            return ForexRateData(
              rate: liveRate,
              previousRate: cached.rate,
              lastUpdated: now,
              isLive: true,
            );
          }
        }
      }
    } catch (_) {
      // Fallback cleanly to cached data on network error / timeout
    }

    return cached;
  }
}
