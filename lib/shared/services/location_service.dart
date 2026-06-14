// 📱 CUSTOMER APP
// lib/shared/services/location_service.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Position? _cachedPosition;
  DateTime? _cachedAt;

  Future<Position?> getCurrentPosition() async {
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
      _cachedAt       = DateTime.now();
      return position;
    } catch (_) {
      return null;
    }
  }

  // ── Opens Android Location Settings directly (not app settings) ───────────
  static Future<void> showEnableLocationDialog(BuildContext context) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (enabled) return;
    if (!context.mounted) return;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Enable Location',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text(
          'Back2Eat needs your location to show nearby restaurants.\n\n'
              'Please turn on Location in your device settings.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not Now',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              // Opens Android Location Settings — GPS toggle is right there
              await Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // ── Opens App Settings when permission permanently denied ─────────────────
  static Future<void> showPermissionDeniedDialog(BuildContext context) async {
    if (!context.mounted) return;
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Location Permission',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text(
          'Location permission is required to find restaurants near you.\n\n'
              'Please enable it in App Settings → Permissions → Location.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await Geolocator.openAppSettings();
            },
            child: const Text('App Settings',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // ── Full flow: check → dialog → get position ──────────────────────────────
  Future<Position?> getPositionWithDialogs(BuildContext context) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await showEnableLocationDialog(context);
      final nowEnabled = await Geolocator.isLocationServiceEnabled();
      if (!nowEnabled) return null;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) await showPermissionDeniedDialog(context);
      return null;
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );
      _cachedPosition = position;
      _cachedAt       = DateTime.now();
      return position;
    } catch (_) {
      return null;
    }
  }

  static double distanceKm(
      double lat1, double lon1,
      double lat2, double lon2,
      ) {
    const r    = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a    = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180;
}