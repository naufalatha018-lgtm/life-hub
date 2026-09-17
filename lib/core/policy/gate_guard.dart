import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_color_palette.dart';
import '../theme/premium_glass_card.dart';
import 'gate.dart';

/// Declarative UI Permission Guard Widget (Laravel Gate Parity).
///
/// Wraps protected UI surfaces and checks against active `userPermissionProfileProvider`.
/// If permitted, renders [child]. If unauthorized, renders [fallback] or a
/// luxury locked executive shield card.
class GateGuard extends ConsumerWidget {
  final String ability;
  final dynamic target;
  final Widget child;
  final Widget? fallback;

  const GateGuard({
    super.key,
    required this.ability,
    this.target,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userPermissionProfileProvider);
    final isAllowed = Gate.allows(
      user: user,
      ability: ability,
      target: target,
    );

    if (isAllowed) {
      return child;
    }

    if (fallback != null) {
      return fallback!;
    }

    // Default ultra-sleek FinTech locked access card
    return PremiumGlassCard(
      blurSigma: 12,
      padding: const EdgeInsets.all(20),
      backgroundColor: AppColorPalette.surfaceElevated.withOpacity(0.75),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColorPalette.crimsonDim.withOpacity(0.60),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColorPalette.crimsonVelvet.withOpacity(0.40),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.lock_person_rounded,
              color: AppColorPalette.crimsonVelvet,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'RESTRICTED ACCESS',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColorPalette.crimsonVelvet,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Membutuhkan izin "$ability". Peran aktif: ${user.role.name.toUpperCase()}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColorPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
