import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Clean Executive Glass/Surface Container for Light Theme.
///
/// Provides subtle frosted blur, crisp white semi-transparent background,
/// soft hairline border (#E2E8F0), and subtle elevation shadow (rgba(0, 0, 0, 0.04)).
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
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

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
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

    Widget content = ClipRRect(
      borderRadius: effectiveRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          alignment: alignment,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: effectiveRadius,
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: boxShadow ??
                [
                  BoxShadow(
                    color: const Color(0x0A000000), // rgba(0, 0, 0, 0.04)
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          borderRadius: effectiveRadius,
          onTap: onTap,
          splashColor: AppColors.primary.withValues(alpha: 0.1),
          highlightColor: AppColors.primary.withValues(alpha: 0.05),
          child: content,
        ),
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
