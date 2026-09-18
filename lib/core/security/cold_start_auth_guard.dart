import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_color_palette.dart';
import '../theme/app_executive_theme.dart';
import 'master_auth_provider.dart';

class ColdStartAuthGuard extends ConsumerStatefulWidget {
  final Widget child;

  const ColdStartAuthGuard({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ColdStartAuthGuard> createState() => _ColdStartAuthGuardState();
}

class _ColdStartAuthGuardState extends ConsumerState<ColdStartAuthGuard>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _isAuthenticating = false;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBiometricIfReady();
      _startLockoutTimerIfNeeded();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _startLockoutTimerIfNeeded() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final authState = ref.read(masterAuthNotifierProvider);
      if (authState.isLockedOut) {
        setState(() {});
      }
    });
  }

  Future<void> _triggerBiometricIfReady() async {
    final authState = ref.read(masterAuthNotifierProvider);
    if (authState.status == MasterAuthStatus.locked && authState.biometricAvailable) {
      setState(() => _isAuthenticating = true);
      final success =
          await ref.read(masterAuthNotifierProvider.notifier).unlockWithBiometrics();
      if (mounted) {
        setState(() => _isAuthenticating = false);
        if (success) {
          HapticFeedback.mediumImpact();
        }
      }
    }
  }

  void _onDigitPressed(String digit) {
    final authState = ref.read(masterAuthNotifierProvider);
    if (authState.isLockedOut || _pin.length >= 6 || _isAuthenticating) return;

    HapticFeedback.lightImpact();
    setState(() {
      _pin += digit;
    });

    if (_pin.length == 6) {
      _submitPin();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty || _isAuthenticating) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  void _onClear() {
    if (_pin.isEmpty || _isAuthenticating) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin = '';
    });
  }

  Future<void> _submitPin() async {
    final enteredPin = _pin;
    setState(() => _isAuthenticating = true);

    final success =
        await ref.read(masterAuthNotifierProvider.notifier).unlockWithPin(enteredPin);

    if (mounted) {
      setState(() {
        _isAuthenticating = false;
        _pin = '';
      });

      if (success) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
        _shakeController.forward(from: 0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(masterAuthNotifierProvider);

    // If loading, show minimal executive branded slate
    if (authState.status == MasterAuthStatus.loading) {
      return const Scaffold(
        backgroundColor: AppColorPalette.surfaceDeepDark,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColorPalette.electricEmerald,
            strokeWidth: 2,
          ),
        ),
      );
    }

    // If unconfigured or already unlocked, render underlying application
    if (authState.status == MasterAuthStatus.unconfigured ||
        authState.status == MasterAuthStatus.unlocked) {
      return widget.child;
    }

    // Locked state: Render Executive Master PIN Screen
    return Scaffold(
      backgroundColor: AppColorPalette.surfaceDeepDark,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: child,
            );
          },
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Top Bar / Status
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColorPalette.surfaceSecondary,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColorPalette.borderSubtle,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            authState.isLockedOut
                                ? Icons.lock_clock_rounded
                                : Icons.shield_rounded,
                            size: 14,
                            color: authState.isLockedOut
                                ? AppColorPalette.crimsonVelvet
                                : AppColorPalette.electricEmerald,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            authState.isLockedOut
                                ? 'SECURITY LOCKOUT'
                                : 'EXECUTIVE FAST-AUTH',
                            style: AppExecutiveTheme.functionalCaption.copyWith(
                              letterSpacing: 0.8,
                              color: authState.isLockedOut
                                  ? AppColorPalette.crimsonVelvet
                                  : AppColorPalette.electricEmerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // Title & Subtitle
              Text(
                'Actividata LifeOS',
                style: AppExecutiveTheme.sectionHeader.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                authState.isLockedOut
                    ? 'Terkunci. Tunggu ${authState.remainingLockoutSeconds} detik.'
                    : 'Masukkan 6-digit Master PIN untuk membuka enkripsi',
                style: AppExecutiveTheme.bodyText.copyWith(
                  fontSize: 13,
                  color: authState.isLockedOut
                      ? AppColorPalette.crimsonVelvet
                      : AppColorPalette.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // 6 Tactile PIN Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: isFilled ? 16 : 14,
                    height: isFilled ? 16 : 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? AppColorPalette.electricEmerald
                          : AppColorPalette.surfaceElevated,
                      border: Border.all(
                        color: isFilled
                            ? AppColorPalette.electricEmerald
                            : AppColorPalette.borderSubtle,
                        width: isFilled ? 2 : 1.5,
                      ),
                      boxShadow: isFilled
                          ? [
                              BoxShadow(
                                color: AppColorPalette.electricEmerald.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                  );
                }),
              ),

              // Error or Status message
              const SizedBox(height: 20),
              SizedBox(
                height: 24,
                child: authState.errorMessage != null
                    ? Text(
                        authState.errorMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColorPalette.crimsonVelvet,
                        ),
                      )
                    : _isAuthenticating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColorPalette.deepAzure,
                            ),
                          )
                        : null,
              ),

              const Spacer(flex: 1),

              // Luxury Executive 3x4 Tactile NumPad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(
                  children: [
                    _buildNumPadRow(['1', '2', '3']),
                    const SizedBox(height: 14),
                    _buildNumPadRow(['4', '5', '6']),
                    const SizedBox(height: 14),
                    _buildNumPadRow(['7', '8', '9']),
                    const SizedBox(height: 14),
                    _buildNumPadBottomRow(authState),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumPadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildKeyButton(d)).toList(),
    );
  }

  Widget _buildNumPadBottomRow(MasterAuthState authState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Biometric Button
        _buildActionButton(
          icon: Icons.fingerprint_rounded,
          color: authState.biometricAvailable
              ? AppColorPalette.electricEmerald
              : AppColorPalette.textMuted,
          onTap: authState.biometricAvailable && !authState.isLockedOut
              ? _triggerBiometricIfReady
              : null,
        ),
        // Digit 0
        _buildKeyButton('0'),
        // Backspace / Clear Button
        _buildActionButton(
          icon: Icons.backspace_outlined,
          color: AppColorPalette.textSecondary,
          onTap: _pin.isNotEmpty ? _onBackspace : null,
          onLongPress: _pin.isNotEmpty ? _onClear : null,
        ),
      ],
    );
  }

  Widget _buildKeyButton(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onDigitPressed(digit),
        borderRadius: BorderRadius.circular(40),
        splashColor: AppColorPalette.electricEmerald.withOpacity(0.15),
        highlightColor: AppColorPalette.surfaceElevated,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColorPalette.surfaceSecondary.withOpacity(0.7),
            border: Border.all(
              color: AppColorPalette.borderSubtle,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            digit,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppColorPalette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(40),
        splashColor: color.withOpacity(0.15),
        highlightColor: AppColorPalette.surfaceElevated,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColorPalette.surfaceSecondary.withOpacity(0.4),
            border: Border.all(
              color: AppColorPalette.borderSubtle.withOpacity(0.5),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 26),
        ),
      ),
    );
  }
}
