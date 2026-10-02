import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../constants/campus_bounds.dart';

class GeolocationResult {
  final LatLng? position;
  final bool isInsideCampus;
  final String? errorMessage;

  GeolocationResult({
    this.position,
    this.isInsideCampus = false,
    this.errorMessage,
  });

  bool get isSuccess => position != null;
}

class GeolocationService {
  /// Fetches current GPS location and checks whether it is inside the student's campus
  static Future<GeolocationResult> getCurrentCampusLocation(
    CampusRegion region,
  ) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return GeolocationResult(
          errorMessage: 'Location services are disabled on your device.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return GeolocationResult(
            errorMessage: 'Location permission was denied.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return GeolocationResult(
          errorMessage:
              'Location permissions are permanently denied. Please enable them in settings.',
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final currentPoint = LatLng(pos.latitude, pos.longitude);
      final isInside = region.contains(currentPoint);

      return GeolocationResult(
        position: currentPoint,
        isInsideCampus: isInside,
      );
    } catch (e) {
      debugPrint('Error getting GPS location: $e');
      final errStr = e.toString().toLowerCase();
      final msg = errStr.contains('permission')
          ? 'Location permission is required to detect your campus position. Please allow location access in app settings.'
          : 'Unable to get current location: $e';
      return GeolocationResult(
        errorMessage: msg,
      );
    }
  }

  /// Resolves human-readable campus place name from coordinates
  static Future<String> resolvePlaceName(
    LatLng point,
    CampusRegion region, {
    String? googleApiKey,
  }) async {
    // 1. Check known campus landmarks first for fastest & accurate campus naming
    final landmark = region.getClosestLandmark(point);
    if (landmark != null) {
      return '${landmark.name}, ${region.university}';
    }

    // 2. Query Google Geocoding API if key is provided
    if (googleApiKey != null && googleApiKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${point.latitude},${point.longitude}&key=$googleApiKey',
        );
        final response = await http.get(url).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
            final formatted = data['results'][0]['formatted_address'] as String;
            return formatted;
          }
        }
      } catch (e) {
        debugPrint('Google Geocoding error: $e');
      }
    }

    // 3. Fallback to OpenStreetMap reverse geocoding
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'CampusFoundApp/1.0'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final name = data['name'] as String?;
        final road = data['address']?['road'] as String?;
        final building = data['address']?['building'] as String?;
        final place = name ?? building ?? road;

        if (place != null && place.isNotEmpty) {
          return '$place, ${region.university}';
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode fallback error: $e');
    }

    // 4. Clean coordinate fallback within university region
    final latStr = point.latitude.toStringAsFixed(4);
    final lngStr = point.longitude.toStringAsFixed(4);
    return 'Campus Location ($latStr, $lngStr), ${region.university}';
  }
}
