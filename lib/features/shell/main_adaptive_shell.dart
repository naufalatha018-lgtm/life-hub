import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/lifecycle/inactivity_lock_manager.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/security/master_auth_provider.dart';
import '../../core/theme/app_color_palette.dart';
import '../auth/providers/auth_provider.dart';
import '../dashboard/views/dashboard_view.dart';
import '../finance/views/finance_view.dart';
import '../notes/providers/notes_crud_provider.dart';
import '../notes/views/secure_notes_view.dart';
import '../settings/providers/settings_providers.dart';
import '../settings/views/settings_view.dart';
import '../tasks/views/tasks_view.dart';
import '../vault/providers/vault_files_provider.dart';
import 'widgets/quick_action_fab.dart';

final activeNavIndexProvider = StateProvider<int>((ref) => 0);

class MainAdaptiveShell extends ConsumerStatefulWidget {
  const MainAdaptiveShell({super.key});

  @override
  ConsumerState<MainAdaptiveShell> createState() => _MainAdaptiveShellState();
}

class _MainAdaptiveShellState extends ConsumerState<MainAdaptiveShell> {
  late InactivityLockManager _lockManager;
  late final FocusNode _keyboardFocusNode;

  int _hudTapCount = 0;
  DateTime? _lastHudTapTime;

  // Tab #1 = Dashboard, #2 = Finance, #3 = Tasks, #4 = Vault, #5 = Settings
  static const List<Widget> _pages = [
    DashboardView(),
    FinanceView(),
    TasksView(),
    SecureNotesView(),
    SettingsView(),
  ];

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode = FocusNode();
    _lockManager = InactivityLockManager(
      timeoutSeconds: AppConstants.autoLockTimeoutSeconds,
      onLockTriggered: () {
        _triggerPanicWipe();
      },
    );
    _lockManager.start();
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _lockManager.dispose();
    super.dispose();
  }

  void _onUserActivity() {
    _lockManager.recordUserActivity();
  }

  void _onNavTap(int index) {
    _onUserActivity();
    HapticFeedback.selectionClick();
    ref.read(activeNavIndexProvider.notifier).state = index;
  }

  /// Instant Panic Wipe Trigger:
  /// Zeroes out RAM, purges decrypted state, and locks the application.
  void _triggerPanicWipe() {
    HapticFeedback.heavyImpact();
    ref.read(masterAuthNotifierProvider.notifier).panicWipe();
    ref.read(decryptedNotesProvider.notifier).purgeMemory();
    ref.read(decryptedVaultFilesProvider.notifier).purgeMemory();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.lock_rounded, color: AppColorPalette.crimsonVelvet, size: 16),
              SizedBox(width: 8),
              Text('PANIC WIPE: Session zeroized & locked'),
            ],
          ),
          backgroundColor: AppColorPalette.surfaceElevated,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Triple-tap detector on top HUD / App Header to instantly trigger Panic Wipe
  void _onHudTap() {
    final now = DateTime.now();
    if (_lastHudTapTime == null || now.difference(_lastHudTapTime!) > const Duration(milliseconds: 600)) {
      _hudTapCount = 1;
    } else {
      _hudTapCount++;
      if (_hudTapCount >= 3) {
        _hudTapCount = 0;
        _triggerPanicWipe();
        return;
      }
    }
    _lastHudTapTime = now;
  }

  void _handleKeyShortcuts(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlOrCmd = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;

      if (isCtrlOrCmd) {
        if (event.logicalKey == LogicalKeyboardKey.digit1) {
          _onNavTap(0);
        } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
          _onNavTap(1);
        } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
          _onNavTap(2);
        } else if (event.logicalKey == LogicalKeyboardKey.digit4) {
          _onNavTap(3);
        } else if (event.logicalKey == LogicalKeyboardKey.digit5) {
          _onNavTap(4);
        } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
          // Instant Panic Wipe trigger on Ctrl+Shift+L or Ctrl+L
          _triggerPanicWipe();
        }
      }
    }
  }

  void _confirmSignOut(BuildContext context) {
    final strings = ref.read(appStringsProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColorPalette.surfaceSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColorPalette.borderSubtle),
        ),
        title: Text(strings.signOutConfirmTitle, style: const TextStyle(color: AppColorPalette.textPrimary)),
        content: Text(strings.signOutConfirmNotice, style: const TextStyle(color: AppColorPalette.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings.cancel, style: const TextStyle(color: AppColorPalette.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColorPalette.crimsonVelvet),
            onPressed: () {
              Navigator.of(ctx).pop();
              _triggerPanicWipe();
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: Text(strings.signOutButton, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(autoLockTimeoutProvider, (prev, next) {
      _lockManager.dispose();
      if (next > 0) {
        _lockManager = InactivityLockManager(
          timeoutSeconds: next,
          onLockTriggered: () {
            _triggerPanicWipe();
          },
        );
        _lockManager.start();
      }
    });

    final currentIndex = ref.watch(activeNavIndexProvider);
    final user = ref.watch(authNotifierProvider).value;
    final strings = ref.watch(appStringsProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: false,
      onKeyEvent: _handleKeyShortcuts,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) {
          _onUserActivity();
          // Check top 70px HUD area for triple tap
          if (e.position.dy < 70) {
            _onHudTap();
          }
        },
        onPointerMove: (_) => _onUserActivity(),
        child: Scaffold(
          backgroundColor: AppColorPalette.surfaceDeepDark,
          floatingActionButton: currentIndex == 0 ? const QuickActionFab() : null,
          body: isDesktop
              ? Row(
                  children: [
                    // Desktop Navigation Rail
                    NavigationRail(
                      backgroundColor: AppColorPalette.surfaceSecondary,
                      selectedIndex: currentIndex,
                      onDestinationSelected: _onNavTap,
                      labelType: NavigationRailLabelType.all,
                      minWidth: 84,
                      leading: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColorPalette.deepAzure,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColorPalette.deepAzure.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.hub_rounded,
                                size: 26,
                                color: Colors.white,
                              ),
                            ),
                            if (user != null) ...[
                              const SizedBox(height: 10),
                              Builder(
                                builder: (context) {
                                  ImageProvider? avatarImg;
                                  if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
                                    if (user.photoUrl!.startsWith('http://') || user.photoUrl!.startsWith('https://')) {
                                      avatarImg = NetworkImage(user.photoUrl!);
                                    } else {
                                      final f = File(user.photoUrl!);
                                      if (f.existsSync()) avatarImg = FileImage(f);
                                    }
                                  }
                                  return Tooltip(
                                    message: '${user.effectiveName}\n(${user.email})',
                                    child: CircleAvatar(
                                      radius: 15,
                                      backgroundColor: AppColorPalette.surfaceElevated,
                                      backgroundImage: avatarImg,
                                      child: avatarImg == null
                                          ? Text(
                                              user.effectiveName.isNotEmpty
                                                  ? user.effectiveName[0].toUpperCase()
                                                  : 'U',
                                              style: const TextStyle(
                                                color: AppColorPalette.electricEmerald,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      trailing: Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: '${strings.lockVault} (Ctrl+Shift+L)',
                                  icon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColorPalette.textMuted),
                                  onPressed: _triggerPanicWipe,
                                ),
                                const SizedBox(height: 6),
                                IconButton(
                                  tooltip: strings.signOutButton,
                                  icon: const Icon(Icons.logout_rounded, size: 18, color: AppColorPalette.crimsonVelvet),
                                  onPressed: () => _confirmSignOut(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      destinations: [
                        NavigationRailDestination(
                          icon: const Icon(Icons.home_outlined, color: AppColorPalette.textSecondary),
                          selectedIcon: const Icon(Icons.home_rounded, color: AppColorPalette.electricEmerald),
                          label: Text(strings.navDashboard, style: const TextStyle(color: AppColorPalette.textPrimary)),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.account_balance_wallet_outlined, color: AppColorPalette.textSecondary),
                          selectedIcon: const Icon(Icons.account_balance_wallet_rounded, color: AppColorPalette.electricEmerald),
                          label: Text(strings.navFinance, style: const TextStyle(color: AppColorPalette.textPrimary)),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.task_alt_outlined, color: AppColorPalette.textSecondary),
                          selectedIcon: const Icon(Icons.task_alt_rounded, color: AppColorPalette.electricEmerald),
                          label: Text(strings.navTasks, style: const TextStyle(color: AppColorPalette.textPrimary)),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.lock_outline_rounded, color: AppColorPalette.textSecondary),
                          selectedIcon: const Icon(Icons.lock_rounded, color: AppColorPalette.electricEmerald),
                          label: Text(strings.navVault, style: const TextStyle(color: AppColorPalette.textPrimary)),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.settings_outlined, color: AppColorPalette.textSecondary),
                          selectedIcon: const Icon(Icons.settings_rounded, color: AppColorPalette.electricEmerald),
                          label: Text(strings.navSettings, style: const TextStyle(color: AppColorPalette.textPrimary)),
                        ),
                      ],
                    ),
                    const VerticalDivider(thickness: 1, width: 1, color: AppColorPalette.borderSubtle),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: KeyedSubtree(
                          key: ValueKey(currentIndex),
                          child: _pages[currentIndex],
                        ),
                      ),
                    ),
                  ],
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: KeyedSubtree(
                    key: ValueKey(currentIndex),
                    child: _pages[currentIndex],
                  ),
                ),
          bottomNavigationBar: isDesktop
              ? null
              : Container(
                  decoration: const BoxDecoration(
                    color: AppColorPalette.surfaceSecondary,
                    border: Border(
                      top: BorderSide(color: AppColorPalette.borderSubtle, width: 1),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: NavigationBar(
                      height: 66,
                      backgroundColor: Colors.transparent,
                      indicatorColor: AppColorPalette.surfaceElevated,
                      elevation: 0,
                      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                      selectedIndex: currentIndex,
                      onDestinationSelected: _onNavTap,
                      destinations: [
                        NavigationDestination(
                          icon: const Icon(Icons.home_outlined, size: 22, color: AppColorPalette.textSecondary),
                          selectedIcon: const Icon(Icons.home_rounded, size: 22, color: AppColorPalette.electricEmerald),
                          label: strings.navDashboard,
                        ),
                        NavigationDestination(
                          icon: const Icon(Icons.account_balance_wallet_outlined, size: 22, color: AppColorPalette.textSecondary),
                          selectedIcon: const Icon(Icons.account_balance_wallet_rounded, size: 22, color: AppColorPalette.electricEmerald),
                          label: strings.navFinance,
                        ),
                        NavigationDestination(
                          icon: const Icon(Icons.task_alt_outlined, size: 22, color: AppColorPalette.textSecondary),
                          selectedIcon: const Icon(Icons.task_alt_rounded, size: 22, color: AppColorPalette.electricEmerald),
                          label: strings.navTasks,
                        ),
                        NavigationDestination(
                          icon: const Icon(Icons.lock_outline_rounded, size: 22, color: AppColorPalette.textSecondary),
                          selectedIcon: const Icon(Icons.lock_rounded, size: 22, color: AppColorPalette.electricEmerald),
                          label: strings.navVault,
                        ),
                        NavigationDestination(
                          icon: const Icon(Icons.settings_outlined, size: 22, color: AppColorPalette.textSecondary),
                          selectedIcon: const Icon(Icons.settings_rounded, size: 22, color: AppColorPalette.electricEmerald),
                          label: strings.navSettings,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
