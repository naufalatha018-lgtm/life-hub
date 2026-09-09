import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  // OTP Resend Countdown
  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _resendCountdown = 30);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  // Password strength computation (0.0 to 1.0)
  double _calculatePasswordStrength(String pass) {
    if (pass.isEmpty) return 0.0;
    double score = 0.0;
    if (pass.length >= 8) score += 0.35;
    if (pass.length >= 12) score += 0.15;
    if (RegExp(r'[A-Za-z]').hasMatch(pass)) score += 0.25;
    if (RegExp(r'[0-9]').hasMatch(pass)) score += 0.25;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(pass)) score += 0.15;
    return score.clamp(0.0, 1.0);
  }

  Color _getStrengthColor(double strength) {
    if (strength <= 0.35) return AppColors.expense;
    if (strength <= 0.7) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String _getStrengthLabel(double strength, strings) {
    if (strength <= 0.35) return strings.passwordStrengthWeak;
    if (strength <= 0.7) return strings.passwordStrengthModerate;
    return strings.passwordStrengthStrong;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    try {
      if (_isSignUp) {
        await ref.read(authNotifierProvider.notifier).signUpLocal(
              email: email,
              password: password,
              displayName: name.isNotEmpty ? name : null,
            );
        _startResendTimer();
        setState(() {
          _successMessage = 'Confirmation code generated. Please verify your email.';
        });
      } else {
        await ref.read(authNotifierProvider.notifier).signInLocal(
              email: email,
              password: password,
            );
      }
    } on UnverifiedAccountException catch (e) {
      _startResendTimer();
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _verifyOtp() async {
    final notifier = ref.read(authNotifierProvider.notifier);
    final email = notifier.pendingVerificationEmail ?? _emailController.text.trim();
    final code = _otpController.text.trim();

    if (code.length < 6) {
      setState(() => _errorMessage = 'Please enter the full 6-digit confirmation code.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await notifier.verifyEmailOtp(email: email, code: code);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _resendOtp() async {
    final notifier = ref.read(authNotifierProvider.notifier);
    final email = notifier.pendingVerificationEmail ?? _emailController.text.trim();
    if (email.isEmpty) return;

    try {
      await notifier.resendVerificationOtp(email);
      _startResendTimer();
      setState(() {
        _errorMessage = null;
        _successMessage = 'A fresh 6-digit confirmation code has been generated.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      _showDesktopGoogleDialog();
      return;
    }

    try {
      await ref.read(authNotifierProvider.notifier).signInGoogle();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _showDesktopGoogleDialog() {
    final strings = ref.read(appStringsProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.cardBorderSubtle),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(Icons.g_mobiledata_rounded, color: Color(0xFF4285F4), size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Google Sign-In',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'Google Sign-In is configured natively for Android devices.\n\n'
          'On Windows Desktop, please use Local Email Sign-In or Continue in Offline Guest Mode for zero-latency local encrypted storage.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings.close, style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _signInGuest() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      await ref.read(authNotifierProvider.notifier).signInGuest();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final notifier = ref.read(authNotifierProvider.notifier);
    final strings = ref.watch(appStringsProvider);
    final isLoading = authState.isLoading;
    final isPendingVerification = notifier.pendingVerificationEmail != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Soft ambient sky blue background glows
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryLight.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Central Card with keyboard inset padding
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 32,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.cardBorderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(32),
                  child: isPendingVerification
                      ? _buildOtpVerificationView(notifier, isLoading, strings)
                      : _buildAuthFormView(isLoading, strings),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- OTP Verification View ---
  Widget _buildOtpVerificationView(AuthNotifier notifier, bool isLoading, strings) {
    final email = notifier.pendingVerificationEmail ?? '';
    final code = notifier.lastSentVerificationCode ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Security Emblem
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGlow,
              border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: AppColors.primary,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            strings.verifyEmailTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            '${strings.verifyEmailSubtitle}\n$email',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Development/Demo Simulation Banner showing the code
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryGlow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Demo: OTP Code is: $code',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Error Banner
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.expenseBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.expense),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.expense, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Success Banner
        if (_successMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.incomeBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.income.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.income),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(color: AppColors.income, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 6-digit Code Input
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: 10,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••••',
            hintStyle: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.4),
              letterSpacing: 10,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 20),

        // Confirm & Activate Button
        ElevatedButton(
          onPressed: isLoading ? null : _verifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  strings.verifyButton,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 14),

        // Resend or Cancel
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _resendCountdown > 0 ? null : _resendOtp,
              child: Text(
                _resendCountdown > 0
                    ? '${strings.resendCodeWait} ${_resendCountdown}s'
                    : strings.resendCode,
                style: TextStyle(
                  color: _resendCountdown > 0 ? AppColors.textMuted : AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                notifier.cancelVerification();
                _otpController.clear();
                setState(() {
                  _errorMessage = null;
                  _successMessage = null;
                });
              },
              child: Text(
                strings.backToSignIn,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Main Auth Form (Sign In / Sign Up) ---
  Widget _buildAuthFormView(bool isLoading, strings) {
    final passwordStrength = _calculatePasswordStrength(_passwordController.text);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Shield Emblem & Branding
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGlow,
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Life Hub',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              _isSignUp ? strings.signUpSubtitle : strings.signInSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Tab Switcher (Sign In vs Sign Up)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => setState(() {
                      _isSignUp = false;
                      _errorMessage = null;
                      _successMessage = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isSignUp ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: !_isSignUp
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        strings.signInTab,
                        style: TextStyle(
                          color: !_isSignUp ? Colors.white : AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => setState(() {
                      _isSignUp = true;
                      _errorMessage = null;
                      _successMessage = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isSignUp ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _isSignUp
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        strings.signUpTab,
                        style: TextStyle(
                          color: _isSignUp ? Colors.white : AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Error Banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.expenseBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.expense),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.expense, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Full Name (if sign up)
          if (_isSignUp) ...[
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: strings.fullNameLabel,
                hintText: 'e.g. Alex Mercer',
                prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textMuted, size: 20),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: strings.emailLabel,
              hintText: 'name@example.com',
              prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.textMuted, size: 20),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Email is required';
              if (!val.contains('@') || !val.contains('.')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            onChanged: (v) {
              if (_isSignUp) setState(() {});
            },
            decoration: InputDecoration(
              labelText: strings.passwordLabel,
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textMuted,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Password is required';
              if (val.trim().length < 8) return 'Password must be at least 8 characters';
              if (_isSignUp) {
                if (!RegExp(r'[A-Za-z]').hasMatch(val) || !RegExp(r'[0-9]').hasMatch(val)) {
                  return 'Must contain both letters and numbers';
                }
              }
              return null;
            },
          ),

          // Password Strength Bar (Sign Up mode only)
          if (_isSignUp && _passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: passwordStrength,
                minHeight: 4,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor(passwordStrength)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _getStrengthLabel(passwordStrength, strings),
              style: TextStyle(
                color: _getStrengthColor(passwordStrength),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Primary Action Button
          ElevatedButton(
            onPressed: isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    _isSignUp ? strings.signUpButton : strings.signInButton,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 18),

          // Divider
          const Row(
            children: [
              Expanded(child: Divider(color: AppColors.cardBorderSubtle)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '•',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
              Expanded(child: Divider(color: AppColors.cardBorderSubtle)),
            ],
          ),
          const SizedBox(height: 16),

          // Google Sign-In Button
          OutlinedButton.icon(
            onPressed: isLoading ? null : _signInWithGoogle,
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(Icons.g_mobiledata_rounded, size: 20, color: Color(0xFF4285F4)),
            ),
            label: Text(
              kIsWeb || defaultTargetPlatform == TargetPlatform.android
                  ? strings.continueWithGoogle
                  : '${strings.continueWithGoogle} (Android)',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppColors.cardBorderSubtle),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),

          // Offline Guest Mode Button with clear badge
          InkWell(
            onTap: isLoading ? null : _signInGuest,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      strings.offlineGuestButton,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

