import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';
import '../theme/glass_container.dart';
import 'location_data.dart';
import 'location_service.dart';

class InteractiveLocationPicker extends StatefulWidget {
  final LocationData? initialLocation;
  final String title;

  const InteractiveLocationPicker({
    super.key,
    this.initialLocation,
    this.title = 'Select Location',
  });

  static Future<LocationData?> show(
    BuildContext context, {
    LocationData? initialLocation,
    String title = 'Select Location',
  }) {
    return showDialog<LocationData>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => InteractiveLocationPicker(
        initialLocation: initialLocation,
        title: title,
      ),
    );
  }

  @override
  State<InteractiveLocationPicker> createState() => _InteractiveLocationPickerState();
}

class _InteractiveLocationPickerState extends State<InteractiveLocationPicker>
    with SingleTickerProviderStateMixin {
  late MapController _mapController;
  late LatLng _currentPoint;
  late TextEditingController _nameController;
  bool _isLocating = false;
  LatLng? _deviceGpsPoint;
  late AnimationController _pulseController;

  static const LatLng _defaultCenter = LatLng(-6.2088, 106.8456); // Jakarta Hub default

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    if (widget.initialLocation != null) {
      _currentPoint = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _nameController = TextEditingController(text: widget.initialLocation!.locationName ?? '');
    } else {
      _currentPoint = _defaultCenter;
      _nameController = TextEditingController();
      _fetchInitialGps();
    }
  }

  Future<void> _fetchInitialGps() async {
    setState(() => _isLocating = true);
    final gps = await LocationService.getCurrentPosition();
    if (!mounted) return;

    setState(() {
      _isLocating = false;
      if (gps != null) {
        _deviceGpsPoint = gps;
        _currentPoint = gps;
        _nameController.text = 'Current Location';
      }
    });

    if (gps != null) {
      _mapController.move(gps, 15.0);
    }
  }

  Future<void> _centerOnGps() async {
    setState(() => _isLocating = true);
    final gps = await LocationService.getCurrentPosition();
    if (!mounted) return;

    setState(() {
      _isLocating = false;
      if (gps != null) {
        _deviceGpsPoint = gps;
        _currentPoint = gps;
        if (_nameController.text.isEmpty || _nameController.text == 'Current Location') {
          _nameController.text = 'Current Location';
        }
      }
    });

    if (gps != null) {
      _mapController.move(gps, 15.0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to acquire GPS signal. Check device permissions.'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nameController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onTapMap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _currentPoint = point;
    });
  }

  void _zoomIn() {
    final zoom = _mapController.camera.zoom + 1;
    _mapController.move(_currentPoint, zoom);
  }

  void _zoomOut() {
    final zoom = _mapController.camera.zoom - 1;
    _mapController.move(_currentPoint, zoom);
  }

  void _selectPreset(String name, LatLng point) {
    setState(() {
      _currentPoint = point;
      _nameController.text = name;
    });
    _mapController.move(point, 14.0);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
        child: GlassContainer(
          blur: 16,
          backgroundColor: const Color(0xF2131722),
          borderColor: AppColors.glassBorderHighlighted,
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGlow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: AppColors.primaryLight, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Location Name Input
              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Location Name / Tag (Optional)',
                  hintText: 'e.g. Headquarters, Downtown Hub, Client Office',
                  prefixIcon: Icon(Icons.label_outline_rounded, size: 20, color: AppColors.primaryLight),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),

              // Presets Bar with GPS Live button
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isLocating ? null : _centerOnGps,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryLight),
                        ),
                        child: Row(
                          children: [
                            _isLocating
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryLight,
                                    ),
                                  )
                                : const Icon(Icons.my_location_rounded, size: 14, color: AppColors.primaryLight),
                            const SizedBox(width: 6),
                            const Text(
                              'Device GPS',
                              style: TextStyle(
                                color: AppColors.primaryLight,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildPresetChip('Hub HQ', const LatLng(-6.2088, 106.8456)),
                    const SizedBox(width: 8),
                    _buildPresetChip('Singapore Office', const LatLng(1.3521, 103.8198)),
                    const SizedBox(width: 8),
                    _buildPresetChip('New York HQ', const LatLng(40.7128, -74.0060)),
                    const SizedBox(width: 8),
                    _buildPresetChip('London Branch', const LatLng(51.5074, -0.1278)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Map View
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentPoint,
                          initialZoom: 14.0,
                          onTap: _onTapMap,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.pauldev.actividata',
                          ),
                          MarkerLayer(
                            markers: [
                              // Optional device GPS pulsing indicator
                              if (_deviceGpsPoint != null && _deviceGpsPoint != _currentPoint)
                                Marker(
                                  point: _deviceGpsPoint!,
                                  width: 28,
                                  height: 28,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blueAccent.withValues(alpha: 0.8),
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              // Active Selected Location Marker with Pulsing Luxury Ring
                              Marker(
                                point: _currentPoint,
                                width: 54,
                                height: 54,
                                child: AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 38 + (_pulseController.value * 16),
                                          height: 38 + (_pulseController.value * 16),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primary.withValues(
                                              alpha: 0.4 - (_pulseController.value * 0.3),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primary,
                                            border: Border.all(color: Colors.white, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary.withValues(alpha: 0.5),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.location_on_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Map overlay controls (Zoom & Coordinates)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMapCircleButton(
                              icon: Icons.my_location_rounded,
                              tooltip: 'Center on Device GPS',
                              onTap: _centerOnGps,
                            ),
                            const SizedBox(height: 8),
                            _buildMapCircleButton(
                              icon: Icons.add_rounded,
                              tooltip: 'Zoom In',
                              onTap: _zoomIn,
                            ),
                            const SizedBox(height: 6),
                            _buildMapCircleButton(
                              icon: Icons.remove_rounded,
                              tooltip: 'Zoom Out',
                              onTap: _zoomOut,
                            ),
                          ],
                        ),
                      ),

                      // Coordinates badge
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xCC131722),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Text(
                            '${_currentPoint.latitude.toStringAsFixed(4)}, ${_currentPoint.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Confirm Location'),
                    onPressed: () {
                      final name = _nameController.text.trim();
                      final result = LocationData(
                        latitude: _currentPoint.latitude,
                        longitude: _currentPoint.longitude,
                        locationName: name.isNotEmpty ? name : null,
                      );
                      Navigator.of(context).pop(result);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String name, LatLng point) {
    final isSelected = (_currentPoint.latitude - point.latitude).abs() < 0.001 &&
        (_currentPoint.longitude - point.longitude).abs() < 0.001;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _selectPreset(name, point),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.25) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : AppColors.cardBorderSubtle,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.place_outlined,
              size: 14,
              color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xE61E2330),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 18, color: Colors.white),
          onPressed: onTap,
        ),
      ),
    );
  }
}
