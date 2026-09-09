import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/lifecycle/inactivity_lock_manager.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../auth/providers/auth_provider.dart';
import '../dashboard/views/dashboard_view.dart';
import '../finance/views/finance_view.dart';
import '../notes/providers/notes_auth_provider.dart';
import '../notes/views/secure_notes_view.dart';
import '../settings/providers/settings_providers.dart';
import '../settings/views/settings_view.dart';
import '../tasks/views/tasks_view.dart';
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
        ref.read(notesAuthNotifierProvider.notifier).lockAndPurge();
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
    HapticFeedback.selectionClick(); // Pillar 21 - haptic nav feedback
    ref.read(activeNavIndexProvider.notifier).state = index;
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
          ref.read(notesAuthNotifierProvider.notifier).lockAndPurge();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vault Locked'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    }
  }

  void _confirmSignOut(BuildContext context) {
    final strings = ref.read(appStringsProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Text(strings.signOutConfirmTitle),
        content: Text(strings.signOutConfirmNotice),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(notesAuthNotifierProvider.notifier).lockAndPurge();
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: Text(strings.signOutButton),
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
            ref.read(notesAuthNotifierProvider.notifier).lockAndPurge();
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
        onPointerDown: (_) => _onUserActivity(),
        onPointerMove: (_) => _onUserActivity(),
        child: Scaffold(
          backgroundColor: AppColors.background,
          floatingActionButton: currentIndex == 0 ? const QuickActionFab() : null,
          body: isDesktop
              ? Row(
                  children: [
                    // Desktop Navigation Rail
                    NavigationRail(
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
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x200284C7),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
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
                              Tooltip(
                                message: '${user.effectiveName}\n(${user.email})',
                                child: CircleAvatar(
                                  radius: 15,
                                  backgroundColor: AppColors.primaryGlow,
                                  child: Text(
                                    user.effectiveName.isNotEmpty
                                        ? user.effectiveName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
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
                                  tooltip: '${strings.lockVault} (Ctrl+L)',
                                  icon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textMuted),
                                  onPressed: () {
                                    ref.read(notesAuthNotifierProvider.notifier).lockAndPurge();
                                  },
                                ),
                                const SizedBox(height: 6),
                                IconButton(
                                  tooltip: strings.signOutButton,
                                  icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.expense),
                                  onPressed: () => _confirmSignOut(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      destinations: [
                        NavigationRailDestination(
                          icon: const Icon(Icons.home_outlined),
                          selectedIcon: const Icon(Icons.home_rounded),
                          label: Text(strings.navDashboard),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.account_balance_wallet_outlined),
                          selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
                          label: Text(strings.navFinance),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.task_alt_outlined),
                          selectedIcon: const Icon(Icons.task_alt_rounded),
                          label: Text(strings.navTasks),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.lock_outline_rounded),
                          selectedIcon: const Icon(Icons.lock_rounded),
                          label: Text(strings.navVault),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.settings_outlined),
                          selectedIcon: const Icon(Icons.settings_rounded),
                          label: Text(strings.navSettings),
                        ),
                      ],
                    ),
                    const VerticalDivider(thickness: 1, width: 1, color: AppColors.cardBorder),
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
              : NavigationBar(
                  selectedIndex: currentIndex,
                  onDestinationSelected: _onNavTap,
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home_rounded),
                      label: strings.navDashboard,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
                      label: strings.navFinance,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.task_alt_outlined),
                      selectedIcon: const Icon(Icons.task_alt_rounded),
                      label: strings.navTasks,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.lock_outline_rounded),
                      selectedIcon: const Icon(Icons.lock_rounded),
                      label: strings.navVault,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings_rounded),
                      label: strings.navSettings,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
