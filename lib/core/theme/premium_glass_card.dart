import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_color_palette.dart';

/// Ultra-Premium FinTech Glassmorphism Card (Stripe & Brex inspired).
///
/// Features:
/// - Real-time BackdropFilter blur (sigma 16x16)
/// - Directional specular alpha gradient borders
/// - Spring-physics scale interpolation on touch (1.0 -> 0.985 -> 1.0)
/// - Integrated tactile haptic feedback (HapticFeedback.lightImpact)
class PremiumGlassCard extends StatefulWidget {
  final Widget child;
  final double blurSigma;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Gradient? borderGradient;
  final double borderWidth;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final bool enableSpringPhysics;
  final List<BoxShadow>? customShadows;

  const PremiumGlassCard({
    super.key,
    required this.child,
    this.blurSigma = 16.0,
    this.borderRadius,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderGradient,
    this.borderWidth = 1.0,
    this.width,
    this.height,
    this.alignment,
    this.enableSpringPhysics = true,
    this.customShadows,
  });

  @override
  State<PremiumGlassCard> createState() => _PremiumGlassCardState();
}

class _PremiumGlassCardState extends State<PremiumGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 240),
    );

    // Spring curve for tactile bounce (scale down to 0.985 on tap down)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.985).animate(
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
    if (widget.onTap != null && widget.enableSpringPhysics) {
      HapticFeedback.lightImpact();
      _springController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null && widget.enableSpringPhysics) {
      _springController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null && widget.enableSpringPhysics) {
      _springController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(20);
    final effectiveBg = widget.backgroundColor ?? AppColorPalette.glassSurface;
    final effectiveBorderGradient =
        widget.borderGradient ?? AppColorPalette.glassBorderGradient;

    Widget cardBody = Container(
      width: widget.width,
      height: widget.height,
      alignment: widget.alignment,
      padding: widget.padding ?? const EdgeInsets.all(18),
      child: widget.child,
    );

    // If blur is active, wrap in BackdropFilter
    if (widget.blurSigma > 0) {
      cardBody = ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blurSigma,
            sigmaY: widget.blurSigma,
          ),
          child: cardBody,
        ),
      );
    } else {
      cardBody = ClipRRect(
        borderRadius: effectiveRadius,
        child: cardBody,
      );
    }

    // Wrap with specular border and layered shadow
    Widget visualCard = Container(
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: widget.customShadows ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.40),
                blurRadius: 24,
                offset: const Offset(0, 10),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: AppColorPalette.deepAzure.withOpacity(0.04),
                blurRadius: 32,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: CustomPaint(
        painter: _GradientBorderPainter(
          radius: effectiveRadius,
          strokeWidth: widget.borderWidth,
          gradient: effectiveBorderGradient,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: effectiveRadius,
          ),
          child: cardBody,
        ),
      ),
    );

    // Interactive spring physics wrapping
    if (widget.onTap != null) {
      visualCard = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: () {
          if (!widget.enableSpringPhysics) {
            HapticFeedback.lightImpact();
          }
          widget.onTap?.call();
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: visualCard,
        ),
      );
    }

    if (widget.margin != null) {
      visualCard = Padding(
        padding: widget.margin!,
        child: visualCard,
      );
    }

    return visualCard;
  }
}

/// Custom painter that draws ultra-fine gradient specular borders around rounded rectangles.
class _GradientBorderPainter extends CustomPainter {
  final BorderRadius radius;
  final double strokeWidth;
  final Gradient gradient;

  _GradientBorderPainter({
    required this.radius,
    required this.strokeWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (strokeWidth <= 0) return;

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final rrect = radius.toRRect(rect);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = gradient.createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius ||
        oldDelegate.gradient != gradient;
  }
}
