import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final locationServiceProvider = Provider((ref) => LocationService());

class LocationService {
  /// Returns the device's current GPS position.
  /// Falls back to Mecca coordinates if location is unavailable.
  Future<Position> getCurrentPosition() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _fallback();

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return _fallback();
      }
      if (permission == LocationPermission.deniedForever) return _fallback();

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return _fallback();
    }
  }

  /// Mecca as a sensible fallback
  Position _fallback() {
    return Position(
      latitude: 21.3891,
      longitude: 39.8579,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}
