import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/app_database.dart';
import 'core/localization/locale_provider.dart';
import 'core/security/cold_start_auth_guard.dart';
import 'core/services/ai_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_color_palette.dart';
import 'core/theme/app_executive_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/views/auth_screen.dart';
import 'features/shell/main_adaptive_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Catch framework errors gracefully ──────────────────────────────────
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('LifeOS FlutterError caught: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('LifeOS PlatformDispatcher error caught: $error\n$stack');
    return true; // prevent engine crash
  };

  // ── Safe database initialization ───────────────────────────────────────
  try {
    await AppDatabase.instance.database;
  } catch (e, st) {
    debugPrint('AppDatabase startup error: $e\n$st');
  }

  // ── Safe notification service & timezone initialization ────────────────
  try {
    await NotificationService.instance.initialize();
  } catch (e, st) {
    debugPrint('NotificationService startup error: $e\n$st');
  }

  // ── Supabase cloud backend (offline fallback if network unavailable) ───
  try {
    await SupabaseService.instance.initialize();
  } catch (e, st) {
    debugPrint('SupabaseService startup error (offline mode): $e\n$st');
  }

  // ── Gemini AI — BYOK, gracefully no-ops if no key is set ──────────────
  try {
    await AiService.instance.initialize();
  } catch (e, st) {
    debugPrint('AiService startup error: $e\n$st');
  }

  runApp(
    const ProviderScope(
      child: LifeOsApp(),
    ),
  );
}

class LifeOsApp extends ConsumerWidget {
  const LifeOsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final activeLanguage = ref.watch(localeProvider);

    final darkExecutiveTheme = AppExecutiveTheme.darkExecutiveTheme;

    return MaterialApp(
      title: 'Actividata',
      debugShowCheckedModeBanner: false,
      locale: Locale(activeLanguage.code),
      theme: darkExecutiveTheme,
      darkTheme: darkExecutiveTheme,
      themeMode: ThemeMode.dark,
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const AuthScreen();
          }
          return const ColdStartAuthGuard(
            child: MainAdaptiveShell(),
          );
        },
        loading: () => const Scaffold(
          backgroundColor: AppColorPalette.surfaceDeepDark,
          body: Center(
            child: CircularProgressIndicator(
              color: AppColorPalette.electricEmerald,
              strokeWidth: 2,
            ),
          ),
        ),
        error: (err, stack) => const AuthScreen(),
      ),
    );
  }
}