import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  LocationService._();

  static const LatLng fallbackDefault = LatLng(-6.2088, 106.8456); // Jakarta Executive Hub

  /// Requests runtime permissions and fetches device's real-time GPS coordinates.
  /// Falls back gracefully to null if services are disabled or permissions denied.
  static Future<LatLng?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      // Graceful fallback on desktop or sensor timeouts
      return null;
    }
  }
}
