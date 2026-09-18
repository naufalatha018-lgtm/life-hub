import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/localization/locale_provider.dart';
import 'package:life_hub/core/security/master_auth_provider.dart';
import 'package:life_hub/features/auth/models/user_model.dart';
import 'package:life_hub/features/auth/providers/auth_provider.dart';
import 'package:life_hub/main.dart';

class MockAuthNotifier extends StateNotifier<AsyncValue<AppUser?>>
    implements AuthNotifier {
  MockAuthNotifier(AppUser? user) : super(AsyncValue.data(user));

  @override
  String? get pendingVerificationEmail => null;

  @override
  String? get lastSentVerificationCode => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLocaleNotifier extends StateNotifier<AppLanguage>
    implements LocaleNotifier {
  MockLocaleNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockMasterAuthNotifier extends StateNotifier<MasterAuthState>
    implements MasterAuthNotifier {
  MockMasterAuthNotifier([MasterAuthStatus status = MasterAuthStatus.unlocked])
      : super(MasterAuthState(status: status));

  @override
  void panicWipe() {}

  @override
  void lock() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('LifeHubApp renders AuthScreen when unauthenticated (Indonesian default)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith((ref) => MockAuthNotifier(null)),
          localeProvider.overrideWith((ref) => MockLocaleNotifier(AppLanguage.id)),
        ],
        child: const LifeOsApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Actividata'), findsOneWidget);
    expect(find.text('Masuk'), findsWidgets);
  });

  testWidgets('LifeHubApp renders MainAdaptiveShell in Bahasa Indonesia by default',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockUser = AppUser(
      id: 'test_user_01',
      email: 'executive@lifehub.corp',
      displayName: 'Executive User',
      photoUrl: null,
      authProvider: 'local',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider
              .overrideWith((ref) => MockAuthNotifier(mockUser)),
          localeProvider
              .overrideWith((ref) => MockLocaleNotifier(AppLanguage.id)),
          masterAuthNotifierProvider
              .overrideWith((ref) => MockMasterAuthNotifier()),
        ],
        child: const LifeOsApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Indonesian adaptive shell navigation labels
    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Keuangan'), findsWidgets);
    expect(find.text('Tugas'), findsWidgets);
    expect(find.text('Brankas'), findsWidgets);
    expect(find.text('Pengaturan'), findsWidgets);
  });

  testWidgets('LifeHubApp renders MainAdaptiveShell in English when locale is English',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockUser = AppUser(
      id: 'test_user_02',
      email: 'executive@lifehub.corp',
      displayName: 'Executive User',
      photoUrl: null,
      authProvider: 'local',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith((ref) => MockAuthNotifier(mockUser)),
          localeProvider.overrideWith((ref) => MockLocaleNotifier(AppLanguage.en)),
          masterAuthNotifierProvider
              .overrideWith((ref) => MockMasterAuthNotifier()),
        ],
        child: const LifeOsApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify English adaptive shell navigation labels
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Finance'), findsWidgets);
    expect(find.text('Tasks'), findsWidgets);
    expect(find.text('Vault'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });
}

