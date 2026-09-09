import 'package:flutter/foundation.dart';

@immutable
class LocationData {
  final double latitude;
  final double longitude;
  final String? locationName;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.locationName,
  });

  String get displayName {
    if (locationName != null && locationName!.trim().isNotEmpty) {
      return locationName!.trim();
    }
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  LocationData copyWith({
    double? latitude,
    double? longitude,
    String? locationName,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
    };
  }

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      locationName: map['location_name'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationData &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          locationName == other.locationName;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode ^ locationName.hashCode;
}
