import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class CampusLandmark {
  final String name;
  final LatLng position;

  const CampusLandmark({required this.name, required this.position});
}

class CampusRegion {
  final String university;
  final LatLng center;
  final LatLngBounds bounds;
  final double minZoom;
  final double maxZoom;
  final double defaultZoom;
  final List<CampusLandmark> landmarks;
  final bool isDynamicallyResolved;

  const CampusRegion({
    required this.university,
    required this.center,
    required this.bounds,
    this.minZoom = 14.5,
    this.maxZoom = 18.5,
    this.defaultZoom = 16.0,
    this.landmarks = const [],
    this.isDynamicallyResolved = false,
  });

  bool contains(LatLng point) {
    return point.latitude >= bounds.south &&
        point.latitude <= bounds.north &&
        point.longitude >= bounds.west &&
        point.longitude <= bounds.east;
  }

  /// Clamps a coordinate so it never leaves the university bounds
  LatLng clamp(LatLng point) {
    final lat = point.latitude.clamp(bounds.south, bounds.north);
    final lng = point.longitude.clamp(bounds.west, bounds.east);
    return LatLng(lat, lng);
  }

  /// Finds the closest known landmark inside this campus
  CampusLandmark? getClosestLandmark(LatLng point) {
    if (landmarks.isEmpty) return null;
    const distance = Distance();
    CampusLandmark? closest;
    double minMeters = double.infinity;

    for (final landmark in landmarks) {
      final meters = distance.as(LengthUnit.Meter, point, landmark.position);
      if (meters < minMeters) {
        minMeters = meters;
        closest = landmark;
      }
    }

    // Only associate if within 300 meters of the landmark
    if (minMeters <= 300) {
      return closest;
    }
    return null;
  }
}

class CampusBounds {
  static final Map<String, CampusRegion> _regions = {
    'Stanford University': CampusRegion(
      university: 'Stanford University',
      center: const LatLng(37.4275, -122.1697),
      bounds: LatLngBounds(
        const LatLng(37.4130, -122.1850), // Southwest
        const LatLng(37.4420, -122.1550), // Northeast
      ),
      landmarks: const [
        CampusLandmark(
          name: 'Main Quad',
          position: LatLng(37.4275, -122.1697),
        ),
        CampusLandmark(
          name: 'Green Library',
          position: LatLng(37.4265, -122.1668),
        ),
        CampusLandmark(
          name: 'Tresidder Student Union',
          position: LatLng(37.4237, -122.1706),
        ),
        CampusLandmark(
          name: 'Huang Engineering Center',
          position: LatLng(37.4278, -122.1742),
        ),
        CampusLandmark(
          name: 'Stanford Memorial Church',
          position: LatLng(37.4270, -122.1702),
        ),
      ],
    ),
    'UC Berkeley': CampusRegion(
      university: 'UC Berkeley',
      center: const LatLng(37.8719, -122.2585),
      bounds: LatLngBounds(
        const LatLng(37.8630, -122.2700),
        const LatLng(37.8810, -122.2470),
      ),
      landmarks: const [
        CampusLandmark(
          name: 'Sather Tower (The Campanile)',
          position: LatLng(37.8721, -122.2578),
        ),
        CampusLandmark(
          name: 'Doe Memorial Library',
          position: LatLng(37.8725, -122.2594),
        ),
        CampusLandmark(
          name: 'Memorial Glade',
          position: LatLng(37.8732, -122.2588),
        ),
        CampusLandmark(
          name: 'Martin Luther King Jr. Student Union',
          position: LatLng(37.8687, -122.2596),
        ),
      ],
    ),
    'MIT': CampusRegion(
      university: 'MIT',
      center: const LatLng(42.3601, -71.0942),
      bounds: LatLngBounds(
        const LatLng(42.3520, -71.1070),
        const LatLng(42.3680, -71.0810),
      ),
      landmarks: const [
        CampusLandmark(
          name: 'Killian Court & Great Dome',
          position: LatLng(42.3591, -71.0935),
        ),
        CampusLandmark(
          name: 'Stata Center (Building 32)',
          position: LatLng(42.3616, -71.0905),
        ),
        CampusLandmark(
          name: 'Student Center (Building W20)',
          position: LatLng(42.3589, -71.0963),
        ),
        CampusLandmark(
          name: 'Hayden Memorial Library',
          position: LatLng(42.3592, -71.0886),
        ),
      ],
    ),
    'Harvard University': CampusRegion(
      university: 'Harvard University',
      center: const LatLng(42.3770, -71.1167),
      bounds: LatLngBounds(
        const LatLng(42.3680, -71.1270),
        const LatLng(42.3850, -71.1060),
      ),
      landmarks: const [
        CampusLandmark(
          name: 'Harvard Yard',
          position: LatLng(42.3744, -71.1169),
        ),
        CampusLandmark(
          name: 'Widener Library',
          position: LatLng(42.3736, -71.1165),
        ),
        CampusLandmark(
          name: 'Annenberg Hall',
          position: LatLng(42.3762, -71.1153),
        ),
        CampusLandmark(
          name: 'Science Center',
          position: LatLng(42.3763, -71.1167),
        ),
      ],
    ),
    'UT Austin': CampusRegion(
      university: 'UT Austin',
      center: const LatLng(30.2849, -97.7341),
      bounds: LatLngBounds(
        const LatLng(30.2760, -97.7440),
        const LatLng(30.2940, -97.7240),
      ),
      landmarks: const [
        CampusLandmark(
          name: 'The UT Tower',
          position: LatLng(30.2862, -97.7394),
        ),
        CampusLandmark(
          name: 'Perry-Castañeda Library',
          position: LatLng(30.2829, -97.7381),
        ),
        CampusLandmark(
          name: 'Texas Union',
          position: LatLng(30.2866, -97.7410),
        ),
      ],
    ),
    'University of Washington': CampusRegion(
      university: 'University of Washington',
      center: const LatLng(47.6553, -122.3035),
      bounds: LatLngBounds(
        const LatLng(47.6460, -122.3160),
        const LatLng(47.6650, -122.2910),
      ),
      landmarks: const [
        CampusLandmark(
          name: 'Red Square',
          position: LatLng(47.6559, -122.3094),
        ),
        CampusLandmark(
          name: 'Suzzallo Library',
          position: LatLng(47.6558, -122.3079),
        ),
        CampusLandmark(
          name: 'The Quad',
          position: LatLng(47.6573, -122.3068),
        ),
        CampusLandmark(
          name: 'HUB (Husky Union Building)',
          position: LatLng(47.6551, -122.3052),
        ),
      ],
    ),
    'NYU': CampusRegion(
      university: 'NYU',
      center: const LatLng(40.7295, -73.9965),
      bounds: LatLngBounds(
        const LatLng(40.7240, -74.0040),
        const LatLng(40.7350, -73.9890),
      ),
      landmarks: const [
        CampusLandmark(
          name: 'Washington Square Park',
          position: LatLng(40.7308, -73.9973),
        ),
        CampusLandmark(
          name: 'Bobst Library',
          position: LatLng(40.7294, -73.9973),
        ),
        CampusLandmark(
          name: 'Kimmel Center for University Life',
          position: LatLng(40.7298, -73.9981),
        ),
      ],
    ),
    'Georgia Tech': CampusRegion(
      university: 'Georgia Tech',
      center: const LatLng(33.7756, -84.3963),
      bounds: LatLngBounds(
        const LatLng(33.7680, -84.4070),
        const LatLng(33.7840, -84.3860),
      ),
      landmarks: const [
        CampusLandmark(
          name: 'Tech Tower',
          position: LatLng(33.7725, -84.3948),
        ),
        CampusLandmark(
          name: 'Clough Undergraduate Learning Commons',
          position: LatLng(33.7749, -84.3963),
        ),
        CampusLandmark(
          name: 'John Lewis Student Center',
          position: LatLng(33.7740, -84.4013),
        ),
      ],
    ),
    'UCLA': CampusRegion(
      university: 'UCLA',
      center: const LatLng(34.0689, -118.4452),
      bounds: LatLngBounds(
        const LatLng(34.0600, -118.4560),
        const LatLng(34.0780, -118.4340),
      ),
      landmarks: const [
        CampusLandmark(
          name: 'Royce Hall',
          position: LatLng(34.0728, -118.4422),
        ),
        CampusLandmark(
          name: 'Powell Library',
          position: LatLng(34.0718, -118.4422),
        ),
        CampusLandmark(
          name: 'Ackerman Union',
          position: LatLng(34.0704, -118.4442),
        ),
      ],
    ),
  };

  // Cache for dynamically resolved universities
  static final Map<String, CampusRegion> _dynamicRegions = {};

  /// Synchronous lookup (checks standard and already-cached dynamic regions)
  static CampusRegion? getRegion(String university) {
    final cleanName = university.toLowerCase().trim();
    if (cleanName.isEmpty) return null;

    for (final entry in _regions.entries) {
      if (entry.key.toLowerCase().trim() == cleanName) {
        return entry.value;
      }
    }

    for (final entry in _dynamicRegions.entries) {
      if (entry.key.toLowerCase().trim() == cleanName) {
        return entry.value;
      }
    }

    return null;
  }

  /// Manually register a custom region in memory
  static void registerCustomRegion(CampusRegion region) {
    _dynamicRegions[region.university.toLowerCase().trim()] = region;
  }

  /// Asynchronously resolves any university name into a CampusRegion.
  /// 1. Checks standard built-in universities.
  /// 2. Checks cached dynamic regions.
  /// 3. Queries OpenStreetMap / Nominatim geocoding API for real coordinates & bounding box.
  /// 4. Falls back to a safe localized region around the center or user GPS hint.
  static Future<CampusRegion> resolveRegion(
    String university, {
    LatLng? userGpsHint,
  }) async {
    final clean = university.trim();
    if (clean.isEmpty) {
      return _defaultFallbackRegion('General Campus', userGpsHint);
    }

    // 1. Check if already known or cached
    final existing = getRegion(clean);
    if (existing != null) {
      return existing;
    }

    // 2. Query Nominatim OpenStreetMap Search API
    try {
      final queryUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(clean)}&format=json&limit=1',
      );
      final response = await http.get(
        queryUrl,
        headers: {'User-Agent': 'CampusFoundApp/1.0'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final item = data[0];
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');

          if (lat != null && lon != null) {
            final center = LatLng(lat, lon);
            LatLngBounds bounds;

            if (item['boundingbox'] != null &&
                (item['boundingbox'] as List).length >= 4) {
              final bbox = item['boundingbox'] as List;
              final south = double.tryParse(bbox[0]?.toString() ?? '') ?? (lat - 0.012);
              final north = double.tryParse(bbox[1]?.toString() ?? '') ?? (lat + 0.012);
              final west = double.tryParse(bbox[2]?.toString() ?? '') ?? (lon - 0.012);
              final east = double.tryParse(bbox[3]?.toString() ?? '') ?? (lon + 0.012);

              // Ensure at least a ~1.2 km campus span around center if boundingbox is too narrow (e.g. single building point)
              const minSpan = 0.010;
              final latSpan = (north - south).abs();
              final lonSpan = (east - west).abs();

              final finalSouth = latSpan < minSpan ? (lat - 0.008) : south;
              final finalNorth = latSpan < minSpan ? (lat + 0.008) : north;
              final finalWest = lonSpan < minSpan ? (lon - 0.008) : west;
              final finalEast = lonSpan < minSpan ? (lon + 0.008) : east;

              bounds = LatLngBounds(
                LatLng(finalSouth, finalWest),
                LatLng(finalNorth, finalEast),
              );
            } else {
              bounds = LatLngBounds(
                LatLng(lat - 0.012, lon - 0.012),
                LatLng(lat + 0.012, lon + 0.012),
              );
            }

            final region = CampusRegion(
              university: clean,
              center: center,
              bounds: bounds,
              defaultZoom: 16.0,
              minZoom: 14.0,
              maxZoom: 19.0,
              isDynamicallyResolved: true,
            );

            _dynamicRegions[clean.toLowerCase()] = region;
            debugPrint('Resolved dynamic campus region for "$clean" at ($lat, $lon)');
            return region;
          }
        }
      }
    } catch (e) {
      debugPrint('Error geocoding university "$clean": $e');
    }

    // 3. Secondary query with "campus" appended if original name had no direct result
    try {
      final campusQueryUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent('$clean campus')}&format=json&limit=1',
      );
      final response = await http.get(
        campusQueryUrl,
        headers: {'User-Agent': 'CampusFoundApp/1.0'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final item = data[0];
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            final center = LatLng(lat, lon);
            final region = CampusRegion(
              university: clean,
              center: center,
              bounds: LatLngBounds(
                LatLng(lat - 0.015, lon - 0.015),
                LatLng(lat + 0.015, lon + 0.015),
              ),
              defaultZoom: 16.0,
              isDynamicallyResolved: true,
            );
            _dynamicRegions[clean.toLowerCase()] = region;
            return region;
          }
        }
      }
    } catch (_) {}

    // 4. Fallback region if geocoding is unavailable or offline
    final fallback = _defaultFallbackRegion(clean, userGpsHint);
    _dynamicRegions[clean.toLowerCase()] = fallback;
    return fallback;
  }

  static CampusRegion _defaultFallbackRegion(
    String university,
    LatLng? userGpsHint,
  ) {
    final center = userGpsHint ?? const LatLng(37.4275, -122.1697);
    return CampusRegion(
      university: university,
      center: center,
      bounds: LatLngBounds(
        LatLng(center.latitude - 0.02, center.longitude - 0.02),
        LatLng(center.latitude + 0.02, center.longitude + 0.02),
      ),
      defaultZoom: 15.5,
      isDynamicallyResolved: true,
    );
  }
}
