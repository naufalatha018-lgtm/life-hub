import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_strings.dart';

enum AppLanguage {
  id('id', 'Bahasa Indonesia'),
  en('en', 'English');

  final String code;
  final String displayName;
  String get languageCode => code;
  const AppLanguage(this.code, this.displayName);
}

const _kLanguageStorageKey = 'app_preferred_language';

class LocaleNotifier extends StateNotifier<AppLanguage> {
  final FlutterSecureStorage _storage;

  LocaleNotifier(this._storage) : super(AppLanguage.id) {
    _loadPersistedLanguage();
  }

  Future<void> _loadPersistedLanguage() async {
    try {
      final savedCode = await _storage.read(key: _kLanguageStorageKey);
      if (savedCode != null) {
        final match = AppLanguage.values.firstWhere(
          (lang) => lang.code == savedCode,
          orElse: () => AppLanguage.id,
        );
        state = match;
      }
    } catch (_) {
      // Fallback to default (id)
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    try {
      await _storage.write(key: _kLanguageStorageKey, value: language.code);
    } catch (_) {}
  }

  Future<void> setLocale(dynamic locale) async {
    if (locale is AppLanguage) {
      await setLanguage(locale);
    } else if (locale is Locale) {
      await setLanguage(locale.languageCode == 'en' ? AppLanguage.en : AppLanguage.id);
    }
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLanguage>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return LocaleNotifier(storage);
});

final appStringsProvider = Provider<AppStrings>((ref) {
  final language = ref.watch(localeProvider);
  switch (language) {
    case AppLanguage.id:
      return const IdAppStrings();
    case AppLanguage.en:
      return const EnAppStrings();
  }
});
