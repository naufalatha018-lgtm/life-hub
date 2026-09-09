import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'interactive_location_picker.dart';
import 'location_data.dart';

class LocationPreviewChip extends StatelessWidget {
  final LocationData? location;
  final ValueChanged<LocationData?> onLocationChanged;
  final bool readOnly;

  const LocationPreviewChip({
    super.key,
    required this.location,
    required this.onLocationChanged,
    this.readOnly = false,
  });

  Future<void> _openPicker(BuildContext context) async {
    final result = await InteractiveLocationPicker.show(
      context,
      initialLocation: location,
    );
    if (result != null) {
      onLocationChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (location == null) {
      if (readOnly) return const SizedBox.shrink();
      return OutlinedButton.icon(
        onPressed: () => _openPicker(context),
        icon: const Icon(Icons.add_location_alt_outlined, size: 16, color: AppColors.primaryLight),
        label: const Text('Add Location Tag', style: TextStyle(fontSize: 13)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          side: const BorderSide(color: AppColors.cardBorderSubtle),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryGlow.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primaryLight),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              location!.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!readOnly) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _openPicker(context),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.edit_location_alt_rounded, size: 14, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => onLocationChanged(null),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close_rounded, size: 14, color: AppColors.expense),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
