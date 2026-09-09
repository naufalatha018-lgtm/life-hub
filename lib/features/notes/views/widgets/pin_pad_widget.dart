import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

class PinPadWidget extends StatefulWidget {
  const PinPadWidget({
    super.key,
    required this.onPinComplete,
    this.title = 'Enter Master PIN',
    this.subtitle = 'Enter your 6-digit PIN to decrypt confidential notes',
    this.stepLabel,
    this.errorMessage,
    this.onBiometricPressed,
    this.showBiometricButton = false,
  });

  final ValueChanged<String> onPinComplete;
  final String title;
  final String subtitle;
  final String? stepLabel;
  final String? errorMessage;
  final VoidCallback? onBiometricPressed;
  final bool showBiometricButton;

  @override
  State<PinPadWidget> createState() => PinPadWidgetState();
}

class PinPadWidgetState extends State<PinPadWidget>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    // Auto-request focus for immediate numeric input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  /// Public method to trigger the invalid PIN shake effect
  void triggerShake() {
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0.0).then((_) {
      _shakeController.reverse();
      setState(() {
        _controller.clear();
      });
      _focusNode.requestFocus();
    });
  }

  void _onTextChanged(String value) {
    setState(() {});
    if (value.length == AppConstants.pinLength) {
      widget.onPinComplete(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enteredPin = _controller.text;

    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Security Shield Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryGlow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 28,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),

              // Step Indicator Pill (e.g. "Langkah 1 dari 2: Buat PIN")
              if (widget.stepLabel != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGlow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.glassBorderHighlighted),
                  ),
                  child: Text(
                    widget.stepLabel!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Title
              Text(
                widget.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                widget.subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 6 PIN Input Cells Stacked with Native Transparent TextField
              Stack(
                alignment: Alignment.center,
                children: [
                  // Visual Cells
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(AppConstants.pinLength, (index) {
                        final hasDigit = index < enteredPin.length;
                        final isCurrent = index == enteredPin.length && _focusNode.hasFocus;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: 44,
                          height: 52,
                          decoration: BoxDecoration(
                            color: hasDigit ? AppColors.surface : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.primary
                                  : (hasDigit ? AppColors.primaryLight : AppColors.cardBorder),
                              width: isCurrent ? 2.0 : 1.2,
                            ),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: hasDigit
                              ? Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : (isCurrent
                                  ? Container(
                                      width: 2,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    )
                                  : null),
                        );
                      }),
                    ),
                  ),

                  // Positioned full-size transparent TextField to capture focus & IME input
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.01,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        enableSuggestions: false,
                        autocorrect: false,
                        showCursor: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(AppConstants.pinLength),
                        ],
                        onChanged: _onTextChanged,
                        enableInteractiveSelection: false,
                      ),
                    ),
                  ),
                ],
              ),

              if (widget.errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(
                  widget.errorMessage!,
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              // Sleek Biometric (Fingerprint / Face ID) Button
              if (widget.showBiometricButton && widget.onBiometricPressed != null) ...[
                const SizedBox(height: 24),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onBiometricPressed,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryGlow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.fingerprint_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Buka dengan Biometrik',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
