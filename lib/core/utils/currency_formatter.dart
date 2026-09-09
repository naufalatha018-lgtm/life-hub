import 'package:intl/intl.dart';

enum AppCurrency {
  usd,
  idr;

  String get code => name.toUpperCase();
  String get label => this == AppCurrency.usd ? r'USD ($)' : 'IDR (Rp)';
  String get symbol => this == AppCurrency.usd ? r'$' : 'Rp ';
}

class CurrencyFormatter {
  CurrencyFormatter._();

  static double _liveIdrPerUsd = 16000.0;
  static int get idrPerUsd => _liveIdrPerUsd.round();
  static double get idrPerCent => _liveIdrPerUsd / 100.0;

  static void setLiveExchangeRate(double rate) {
    if (rate > 0) {
      _liveIdrPerUsd = rate;
    }
  }

  static void resetToDefaultExchangeRate() {
    _liveIdrPerUsd = 16000.0;
  }

  static double get currentExchangeRate => _liveIdrPerUsd;

  static final NumberFormat _usdFormat = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 2,
  );

  static final NumberFormat _idrFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Converts USD cents to IDR amount using active rate.
  static int centsToIdr(int amountCents) => (amountCents * idrPerCent).round();

  /// Converts IDR amount to USD cents using active rate.
  static int idrToCents(int idrAmount) => (idrAmount / idrPerCent).round();

  /// Converts integer cents to formatted currency string in USD or IDR.
  /// Example (USD): 1050 -> "$10.50", -2500 -> "-$25.00"
  /// Example (IDR): 100 cents = $1.00 = 16,000 IDR -> "Rp 16.000"
  static String formatCents(
    int amountCents, {
    bool showSign = false,
    AppCurrency currency = AppCurrency.usd,
  }) {
    if (currency == AppCurrency.idr) {
      final idrValue = (amountCents * idrPerCent).round();
      final formatted = _idrFormat.format(idrValue.abs()).trim();
      if (amountCents < 0) {
        return '-$formatted';
      } else if (showSign && amountCents > 0) {
        return '+$formatted';
      }
      return formatted;
    }

    final double value = amountCents / 100.0;
    if (showSign && amountCents > 0) {
      return '+${_usdFormat.format(value)}';
    }
    return _usdFormat.format(value);
  }

  /// Converts integer cents to compact currency representation.
  /// USD: $1.2K, $2.5M
  /// IDR: Rp 160K, Rp 1.6M, Rp 16M
  static String formatCompactCents(
    int amountCents, {
    AppCurrency currency = AppCurrency.usd,
  }) {
    if (currency == AppCurrency.idr) {
      final double idr = (amountCents * idrPerCent).toDouble();
      if (idr.abs() >= 1000000000) {
        return 'Rp ${(idr / 1000000000).toStringAsFixed(1)}B';
      } else if (idr.abs() >= 1000000) {
        return 'Rp ${(idr / 1000000).toStringAsFixed(1)}M';
      } else if (idr.abs() >= 1000) {
        return 'Rp ${(idr / 1000).toStringAsFixed(0)}K';
      }
      return _idrFormat.format(idr).trim();
    }

    final double value = amountCents / 100.0;
    if (value.abs() >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    }
    return _usdFormat.format(value);
  }

  /// Parses user-entered text into integer cents based on selected currency.
  /// Eliminates all floating-point precision loss.
  static int parseToCents(
    String input, {
    AppCurrency currency = AppCurrency.usd,
  }) {
    if (currency == AppCurrency.idr) {
      // In IDR, user types e.g. "50000" or "50.000" or "Rp 50.000"
      final clean = input.replaceAll(RegExp(r'[^0-9]'), '').trim();
      if (clean.isEmpty) return 0;
      final idrAmount = int.tryParse(clean) ?? 0;
      return (idrAmount / idrPerCent).round();
    }

    final clean = input.replaceAll(RegExp(r'[^0-9.]'), '').trim();
    if (clean.isEmpty) return 0;

    final parts = clean.split('.');
    final wholePart = int.tryParse(parts[0]) ?? 0;

    int centPart = 0;
    if (parts.length > 1) {
      String fraction = parts[1];
      if (fraction.length == 1) {
        fraction = '${fraction}0';
      } else if (fraction.length > 2) {
        fraction = fraction.substring(0, 2);
      }
      centPart = int.tryParse(fraction) ?? 0;
    }

    return (wholePart * 100) + centPart;
  }
}
