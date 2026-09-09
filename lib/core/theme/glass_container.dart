import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Clean Executive Glass/Surface Container for Light Theme.
///
/// Optimized for 60fps/120fps scrolling by eliminating expensive offscreen
/// [BackdropFilter] GPU passes during list scrolling while maintaining the
/// signature Notion/fintech frosted aesthetic via calibrated surface opacities,
/// hairline borders (#E2E8F0), and soft ambient shadows.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final bool enableBlur;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  /// Global toggle for backdrop filter blur. Disabled by default to ensure
  /// zero frame drops and 60fps scrolling on mobile devices.
  static bool globalBlurEnabled = false;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 0.0,
    this.enableBlur = false,
    this.backgroundColor = AppColors.glassBackground,
    this.borderColor = AppColors.glassBorder,
    this.borderWidth = 1.0,
    this.borderRadius,
    this.padding,
    this.margin,
    this.onTap,
    this.boxShadow,
    this.width,
    this.height,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(16);
    final shouldBlur = (enableBlur || globalBlurEnabled) && blur > 0;

    final decoration = BoxDecoration(
      color: backgroundColor,
      borderRadius: effectiveRadius,
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: boxShadow ??
          const [
            BoxShadow(
              color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
    );

    Widget innerChild = child;
    if (onTap != null) {
      innerChild = Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          borderRadius: effectiveRadius,
          onTap: onTap,
          splashColor: AppColors.primary.withOpacity(0.08),
          highlightColor: AppColors.primary.withOpacity(0.04),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      );
    } else if (padding != null) {
      innerChild = Padding(
        padding: padding!,
        child: child,
      );
    }

    Widget content;
    if (shouldBlur) {
      content = RepaintBoundary(
        child: Container(
          width: width,
          height: height,
          alignment: alignment,
          decoration: decoration,
          child: ClipRRect(
            borderRadius: effectiveRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: innerChild,
            ),
          ),
        ),
      );
    } else {
      content = Container(
        width: width,
        height: height,
        alignment: alignment,
        decoration: decoration,
        child: innerChild,
      );
    }

    if (margin != null) {
      content = Padding(
        padding: margin!,
        child: content,
      );
    }

    return content;
  }
}
