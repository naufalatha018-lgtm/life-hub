import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/location/location_data.dart';
import '../../../../../core/theme/app_color_palette.dart';

/// A compact geo-tag pill that displays a transaction's geocoded location.
///
/// Shows the merchant / location name when available, or falls back to
/// formatted lat/lon coordinates. Optionally tappable to open a link.
class LocationTagWidget extends StatelessWidget {
  final LocationData location;

  /// Maximum characters to show before truncating the label.
  final int maxLabelLength;

  const LocationTagWidget({
    super.key,
    required this.location,
    this.maxLabelLength = 28,
  });

  String get _truncatedLabel {
    final name = location.displayName;
    if (name.length <= maxLabelLength) return name;
    return '${name.substring(0, maxLabelLength - 1)}…';
  }

  /// True if the location has a resolved name (not raw coords).
  bool get _hasResolvedName =>
      location.locationName != null && location.locationName!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColorPalette.azureDim.withOpacity(0.45),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColorPalette.deepAzure.withOpacity(0.30),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _hasResolvedName ? Icons.store_outlined : Icons.near_me_outlined,
            size: 10,
            color: AppColorPalette.azureLight,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _truncatedLabel,
              style: GoogleFonts.inter(
                color: AppColorPalette.azureLight,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
