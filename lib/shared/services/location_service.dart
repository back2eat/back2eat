import 'dart:math';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Position? _cachedPosition;
  DateTime? _cachedAt;

  /// Returns current device position, or null if permission denied / unavailable
  Future<Position?> getCurrentPosition() async {
    // Return cached position if less than 2 minutes old
    if (_cachedPosition != null && _cachedAt != null &&
        DateTime.now().difference(_cachedAt!).inMinutes < 2) {
      return _cachedPosition;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );
      _cachedPosition = position;
      _cachedAt = DateTime.now();
      return position;
    } catch (_) {
      return null;
    }
  }

  /// Calculate distance in km between two lat/lng points using Haversine formula
  static double distanceKm(
      double lat1, double lon1,
      double lat2, double lon2,
      ) {
    const r = 6371.0; // Earth radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRad(double deg) => deg * pi / 180;
}