import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/forex_service.dart';
import 'currency_formatter.dart';

class CurrencyNotifier extends StateNotifier<AppCurrency> {
  final FlutterSecureStorage _storage;
  static const _storageKey = 'preferred_currency';

  CurrencyNotifier(this._storage) : super(AppCurrency.usd) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved == 'idr') {
        state = AppCurrency.idr;
      } else {
        state = AppCurrency.usd;
      }
    } catch (_) {
      // Fallback default
    }
  }

  Future<void> toggleCurrency() async {
    final next = state == AppCurrency.usd ? AppCurrency.idr : AppCurrency.usd;
    state = next;
    try {
      await _storage.write(
        key: _storageKey,
        value: next == AppCurrency.idr ? 'idr' : 'usd',
      );
    } catch (_) {}
  }

  Future<void> setCurrency(AppCurrency currency) async {
    state = currency;
    try {
      await _storage.write(
        key: _storageKey,
        value: currency == AppCurrency.idr ? 'idr' : 'usd',
      );
    } catch (_) {}
  }
}

final currencyStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final activeCurrencyProvider =
    StateNotifierProvider<CurrencyNotifier, AppCurrency>((ref) {
  final storage = ref.watch(currencyStorageProvider);
  return CurrencyNotifier(storage);
});

class ForexState {
  final double rate;
  final double previousRate;
  final DateTime lastUpdated;
  final bool isFetching;
  final bool isLive;
  final String? errorMessage;

  const ForexState({
    required this.rate,
    required this.previousRate,
    required this.lastUpdated,
    required this.isFetching,
    required this.isLive,
    this.errorMessage,
  });

  double get usdToIdr => rate;
  double get changeDelta => previousRate > 0 ? rate - previousRate : 0.0;
  double get changePercentage =>
      previousRate > 0 ? ((rate - previousRate) / previousRate) * 100 : 0.0;
  double? get deltaPercent => changePercentage;

  ForexState copyWith({
    double? rate,
    double? previousRate,
    DateTime? lastUpdated,
    bool? isFetching,
    bool? isLive,
    String? errorMessage,
  }) {
    return ForexState(
      rate: rate ?? this.rate,
      previousRate: previousRate ?? this.previousRate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isFetching: isFetching ?? this.isFetching,
      isLive: isLive ?? this.isLive,
      errorMessage: errorMessage,
    );
  }
}

class ForexNotifier extends StateNotifier<ForexState> {
  final ForexService _service;

  ForexNotifier(this._service)
      : super(
          ForexState(
            rate: ForexService.defaultRate,
            previousRate: ForexService.defaultRate,
            lastUpdated: DateTime.now(),
            isFetching: false,
            isLive: false,
          ),
        ) {
    _initialize();
  }

  Future<void> _initialize() async {
    final cached = await _service.loadCachedRate();
    CurrencyFormatter.setLiveExchangeRate(cached.rate);
    state = ForexState(
      rate: cached.rate,
      previousRate: cached.previousRate,
      lastUpdated: cached.lastUpdated,
      isFetching: false,
      isLive: false,
    );
    await refreshRate();
  }

  Future<ForexRateData?> refreshRate() async {
    state = state.copyWith(isFetching: true, errorMessage: null);
    try {
      final liveData = await _service.fetchLiveRate();
      CurrencyFormatter.setLiveExchangeRate(liveData.rate);
      state = ForexState(
        rate: liveData.rate,
        previousRate: liveData.previousRate,
        lastUpdated: liveData.lastUpdated,
        isFetching: false,
        isLive: liveData.isLive,
      );
      return liveData;
    } catch (e) {
      state = state.copyWith(
        isFetching: false,
        errorMessage: 'Unable to refresh rates: $e',
      );
      return null;
    }
  }

  Future<void> syncRates() async {
    await refreshRate();
  }
}

final forexServiceProvider = Provider<ForexService>((ref) {
  final storage = ref.watch(currencyStorageProvider);
  return ForexService(storage: storage);
});

final forexRateProvider = StateNotifierProvider<ForexNotifier, ForexState>((ref) {
  final service = ref.watch(forexServiceProvider);
  return ForexNotifier(service);
});

// Alias for seamless backward and forward compatibility
final currencyNotifierProvider = activeCurrencyProvider;
