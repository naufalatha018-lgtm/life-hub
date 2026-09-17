import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_color_palette.dart';

enum ExecutiveButtonVariant {
  primaryBrand, // Deep Azure -> Light Indigo gradient
  electricEmerald, // Electric Emerald -> Teal gradient
  glassOutline, // Ultra-thin alpha border with frosted fill
  crimsonAlert, // Crimson Velvet alert gradient
}

/// Custom Executive Interactive Button.
///
/// Strictly replaces generic `ElevatedButton` and `OutlinedButton` with
/// tactile haptic feedback, spring physics scale, custom specular glow, and
/// high-legibility typography.
class ExecutiveButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ExecutiveButtonVariant variant;
  final bool isLoading;
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const ExecutiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = ExecutiveButtonVariant.primaryBrand,
    this.isLoading = false,
    this.height = 48.0,
    this.width,
    this.borderRadius,
    this.padding,
  });

  @override
  State<ExecutiveButton> createState() => _ExecutiveButtonState();
}

class _ExecutiveButtonState extends State<ExecutiveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _springController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      HapticFeedback.lightImpact();
      _springController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _springController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _springController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(14);
    final isDisabled = widget.onPressed == null || widget.isLoading;

    Gradient? gradient;
    Color? solidBg;
    Border? border;
    Color textColor = AppColorPalette.textPrimary;
    Color spinnerColor = Colors.white;
    List<BoxShadow> shadows = [];

    switch (widget.variant) {
      case ExecutiveButtonVariant.primaryBrand:
        gradient = isDisabled
            ? null
            : AppColorPalette.brandAccentGradient;
        solidBg = isDisabled ? AppColorPalette.surfaceInteractive : null;
        border = Border.all(color: Colors.white.withOpacity(0.12), width: 1);
        shadows = isDisabled
            ? []
            : [
                BoxShadow(
                  color: AppColorPalette.deepAzure.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ];
        break;

      case ExecutiveButtonVariant.electricEmerald:
        gradient = isDisabled
            ? null
            : AppColorPalette.emeraldAccentGradient;
        solidBg = isDisabled ? AppColorPalette.surfaceInteractive : null;
        border = Border.all(color: Colors.white.withOpacity(0.15), width: 1);
        textColor = const Color(0xFF031A12); // Deep dark emerald for contrast
        spinnerColor = const Color(0xFF031A12);
        shadows = isDisabled
            ? []
            : [
                BoxShadow(
                  color: AppColorPalette.electricEmerald.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ];
        break;

      case ExecutiveButtonVariant.glassOutline:
        solidBg = AppColorPalette.surfaceElevated.withOpacity(0.60);
        border = Border.all(color: AppColorPalette.borderHighlight, width: 1);
        textColor = AppColorPalette.textPrimary;
        shadows = [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ];
        break;

      case ExecutiveButtonVariant.crimsonAlert:
        gradient = isDisabled
            ? null
            : AppColorPalette.crimsonAccentGradient;
        solidBg = isDisabled ? AppColorPalette.surfaceInteractive : null;
        border = Border.all(color: Colors.white.withOpacity(0.15), width: 1);
        shadows = isDisabled
            ? []
            : [
                BoxShadow(
                  color: AppColorPalette.crimsonVelvet.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ];
        break;
    }

    Widget content;
    if (widget.isLoading) {
      content = Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
          ),
        ),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 18, color: textColor),
            const SizedBox(width: 8),
          ],
          Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: textColor,
            ),
          ),
        ],
      );
    }

    Widget button = Container(
      height: widget.height,
      width: widget.width,
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: solidBg,
        gradient: gradient,
        borderRadius: effectiveRadius,
        border: border,
        boxShadow: shadows,
      ),
      child: content,
    );

    if (!isDisabled) {
      button = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onPressed?.call();
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: button,
        ),
      );
    } else {
      button = Opacity(
        opacity: 0.55,
        child: button,
      );
    }

    return button;
  }
}
