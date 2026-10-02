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
  final double radiusMeters;
  final double minZoom;
  final double maxZoom;
  final double defaultZoom;
  final List<CampusLandmark> landmarks;
  final bool isDynamicallyResolved;

  CampusRegion({
    required this.university,
    required this.center,
    LatLngBounds? bounds,
    this.radiusMeters = 600.0,
    this.minZoom = 14.5,
    this.maxZoom = 18.5,
    this.defaultZoom = 16.0,
    this.landmarks = const [],
    this.isDynamicallyResolved = false,
  }) : bounds = bounds ?? boundsFromCenterRadius(center, radiusMeters);

  /// Helper to calculate the bounding envelope enclosing the circular campus area
  static LatLngBounds boundsFromCenterRadius(LatLng center, double radiusMeters) {
    const distance = Distance();
    final marginMeters = radiusMeters * 1.35;
    final north = distance.offset(center, marginMeters, 0).latitude;
    final south = distance.offset(center, marginMeters, 180).latitude;
    final east = distance.offset(center, marginMeters, 90).longitude;
    final west = distance.offset(center, marginMeters, 270).longitude;
    return LatLngBounds(LatLng(south, west), LatLng(north, east));
  }

  /// Checks if a point lies within the circular campus boundary
  bool contains(LatLng point) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, center, point) <= radiusMeters;
  }

  /// Clamps a coordinate so it stays within the circular university perimeter
  LatLng clamp(LatLng point) {
    const distance = Distance();
    final d = distance.as(LengthUnit.Meter, center, point);
    if (d <= radiusMeters) {
      return point;
    }
    final bearing = distance.bearing(center, point);
    return distance.offset(center, radiusMeters, bearing);
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
      radiusMeters: 750.0,
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
    'Darshan University, Rajkot': CampusRegion(
      university: 'Darshan University, Rajkot',
      center: const LatLng(22.430654, 70.784714),
      radiusMeters: 500.0, // 22-acre campus zone on Rajkot-Morbi Highway, Hadala
      defaultZoom: 16.5,
      landmarks: const [
        CampusLandmark(
          name: 'Main Academic Block',
          position: LatLng(22.430654, 70.784714),
        ),
        CampusLandmark(
          name: 'Computer Engineering & IT Dept',
          position: LatLng(22.4302, 70.7852),
        ),
        CampusLandmark(
          name: 'Mechanical & Civil Dept Block',
          position: LatLng(22.4312, 70.7841),
        ),
        CampusLandmark(
          name: 'Central Library & Admin Block',
          position: LatLng(22.4305, 70.7844),
        ),
        CampusLandmark(
          name: 'Student Cafeteria & Canteen',
          position: LatLng(22.4298, 70.7849),
        ),
        CampusLandmark(
          name: 'Sports Ground & Campus Turf',
          position: LatLng(22.4315, 70.7858),
        ),
        CampusLandmark(
          name: 'Main Campus Entrance Gate',
          position: LatLng(22.4303, 70.7838),
        ),
      ],
    ),
    'Dharmsinh Desai University (DDU)': CampusRegion(
      university: 'Dharmsinh Desai University (DDU)',
      center: const LatLng(22.6800, 72.8803),
      radiusMeters: 450.0,
      defaultZoom: 16.5,
      landmarks: const [
        CampusLandmark(
          name: 'Main Administrative Block',
          position: LatLng(22.6800, 72.8803),
        ),
        CampusLandmark(
          name: 'Faculty of Technology',
          position: LatLng(22.6804, 72.8808),
        ),
        CampusLandmark(
          name: 'Central Library',
          position: LatLng(22.6796, 72.8801),
        ),
      ],
    ),
    'Marwadi University, Rajkot': CampusRegion(
      university: 'Marwadi University, Rajkot',
      center: const LatLng(22.3676, 70.7971),
      radiusMeters: 650.0,
      defaultZoom: 16.0,
      landmarks: const [
        CampusLandmark(
          name: 'Main Academic Building',
          position: LatLng(22.3676, 70.7971),
        ),
        CampusLandmark(
          name: 'Engineering Faculty Block',
          position: LatLng(22.3682, 70.7965),
        ),
        CampusLandmark(
          name: 'Marwadi University Lake',
          position: LatLng(22.3667, 70.7961),
        ),
      ],
    ),
    'Saurashtra University, Rajkot': CampusRegion(
      university: 'Saurashtra University, Rajkot',
      center: const LatLng(22.2897, 70.7583),
      radiusMeters: 800.0,
      defaultZoom: 15.5,
      landmarks: const [
        CampusLandmark(
          name: 'Senate Hall & Admin',
          position: LatLng(22.2897, 70.7583),
        ),
        CampusLandmark(
          name: 'Central Library',
          position: LatLng(22.2905, 70.7591),
        ),
      ],
    ),
    'Nirma University, Ahmedabad': CampusRegion(
      university: 'Nirma University, Ahmedabad',
      center: const LatLng(23.1287, 72.5445),
      radiusMeters: 650.0,
      defaultZoom: 16.0,
      landmarks: const [
        CampusLandmark(
          name: 'Institute of Technology',
          position: LatLng(23.1287, 72.5445),
        ),
      ],
    ),
    'RK University, Rajkot': CampusRegion(
      university: 'RK University, Rajkot',
      center: const LatLng(22.2427, 70.9016),
      radiusMeters: 600.0,
      defaultZoom: 16.0,
      landmarks: const [
        CampusLandmark(
          name: 'Main Academic Block',
          position: LatLng(22.2427, 70.9016),
        ),
      ],
    ),
  };

  // Cache for dynamically resolved universities
  static final Map<String, CampusRegion> _dynamicRegions = {};

  /// Synchronous lookup (checks standard and already-cached dynamic regions + fuzzy alias recognition)
  static CampusRegion? getRegion(String university) {
    final cleanName = university
        .toLowerCase()
        .replaceAll(RegExp(r'[,.\-_]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleanName.isEmpty) return null;

    // 1. Direct match in standard regions
    for (final entry in _regions.entries) {
      final entryClean = entry.key
          .toLowerCase()
          .replaceAll(RegExp(r'[,.\-_]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (entryClean == cleanName) {
        return entry.value;
      }
    }

    // 2. Direct match in dynamic cached regions
    for (final entry in _dynamicRegions.entries) {
      final entryClean = entry.key
          .toLowerCase()
          .replaceAll(RegExp(r'[,.\-_]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (entryClean == cleanName) {
        return entry.value;
      }
    }

    // 3. Intelligent fuzzy alias matching for common campus queries
    if (cleanName.contains('darshan')) {
      return _regions['Darshan University, Rajkot'];
    }
    if (cleanName.contains('ddu') || cleanName.contains('dharmsinh')) {
      return _regions['Dharmsinh Desai University (DDU)'];
    }
    if (cleanName.contains('marwadi')) {
      return _regions['Marwadi University, Rajkot'];
    }
    if (cleanName.contains('saurashtra')) {
      return _regions['Saurashtra University, Rajkot'];
    }
    if (cleanName.contains('nirma')) {
      return _regions['Nirma University, Ahmedabad'];
    }
    if (cleanName.contains('rk university') || (cleanName.contains('rk') && cleanName.contains('rajkot'))) {
      return _regions['RK University, Rajkot'];
    }
    if (cleanName.contains('stanford')) {
      return _regions['Stanford University'];
    }
    if (cleanName.contains('berkeley')) {
      return _regions['UC Berkeley'];
    }
    if (cleanName == 'mit' || cleanName.contains('massachusetts institute')) {
      return _regions['MIT'];
    }
    if (cleanName.contains('harvard')) {
      return _regions['Harvard University'];
    }
    if (cleanName.contains('austin') || cleanName.contains('ut austin')) {
      return _regions['UT Austin'];
    }
    if (cleanName.contains('washington') && cleanName.contains('university')) {
      return _regions['University of Washington'];
    }
    if (cleanName == 'nyu' || cleanName.contains('new york university')) {
      return _regions['NYU'];
    }
    if (cleanName.contains('georgia tech')) {
      return _regions['Georgia Tech'];
    }
    if (cleanName == 'ucla') {
      return _regions['UCLA'];
    }

    return null;
  }

  /// Manually register a custom region in memory
  static void registerCustomRegion(CampusRegion region) {
    _dynamicRegions[region.university.toLowerCase().trim()] = region;
  }

  /// Returns the canonical display name for a university if known, or cleaned name
  static String canonicalUniversityName(String university) {
    final clean = university.trim();
    if (clean.isEmpty) return 'General Campus';
    final region = getRegion(clean);
    if (region != null) {
      return region.university;
    }
    return clean;
  }

  /// Case-insensitive comparison of two university names.
  /// E.g. "harvard" and "Harvard" are identical, and both match "Harvard University".
  static bool isSameUniversity(String? uniA, String? uniB) {
    if (uniA == null || uniB == null) return false;
    final cleanA = uniA.trim().toLowerCase();
    final cleanB = uniB.trim().toLowerCase();
    if (cleanA.isEmpty || cleanB.isEmpty) return false;
    if (cleanA == cleanB) return true;

    // Check if both resolve to the same known campus region
    final regionA = getRegion(cleanA);
    final regionB = getRegion(cleanB);
    if (regionA != null && regionB != null) {
      return regionA.university.toLowerCase() == regionB.university.toLowerCase();
    }
    return false;
  }

  /// Asynchronously resolves any university name into a circular CampusRegion.
  /// 1. Checks standard built-in universities and fuzzy aliases.
  /// 2. Queries Photon Komoot API (fuzzy OSM search).
  /// 3. Queries OpenStreetMap / Nominatim geocoding API.
  /// 4. Falls back to detecting the city in the name or user GPS hint.
  /// Never defaults to Stanford California for non-Stanford searches!
  static Future<CampusRegion> resolveRegion(
    String university, {
    LatLng? userGpsHint,
  }) async {
    final clean = university.trim();
    if (clean.isEmpty) {
      return _defaultFallbackRegion('General Campus', userGpsHint);
    }

    // 1. Check if already known via standard or fuzzy match
    final existing = getRegion(clean);
    if (existing != null) {
      _dynamicRegions[clean.toLowerCase().trim()] = existing;
      return existing;
    }

    // 2. Query Photon Komoot Search API (fuzzy, typo-tolerant OpenStreetMap geocoder)
    try {
      final photonUrl = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(clean)}&limit=3',
      );
      final response =
          await http.get(photonUrl).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List features = data['features'] as List? ?? [];
        if (features.isNotEmpty) {
          final geom = features[0]['geometry'];
          if (geom != null && geom['coordinates'] != null) {
            final coords = geom['coordinates'] as List;
            final lon = (coords[0] as num).toDouble();
            final lat = (coords[1] as num).toDouble();
            final center = LatLng(lat, lon);

            final region = CampusRegion(
              university: clean,
              center: center,
              radiusMeters: 600.0,
              defaultZoom: 16.0,
              isDynamicallyResolved: true,
            );
            _dynamicRegions[clean.toLowerCase().trim()] = region;
            debugPrint('Resolved dynamic campus "$clean" via Photon at ($lat, $lon)');
            return region;
          }
        }
      }
    } catch (e) {
      debugPrint('Photon geocoding error: $e');
    }

    // 3. Query OpenStreetMap / Nominatim Search API
    try {
      final queryUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(clean)}&format=json&limit=1',
      );
      final response = await http.get(
        queryUrl,
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
              radiusMeters: 600.0,
              defaultZoom: 16.0,
              isDynamicallyResolved: true,
            );

            _dynamicRegions[clean.toLowerCase().trim()] = region;
            debugPrint('Resolved dynamic campus "$clean" via Nominatim at ($lat, $lon)');
            return region;
          }
        }
      }
    } catch (e) {
      debugPrint('Nominatim geocoding error: $e');
    }

    // 4. City / Locality Geocoding Fallback:
    // If the specific campus isn't indexed, extract the city name from the string and center at that city!
    final detectedCity = _extractCity(clean);
    if (detectedCity != null) {
      try {
        final cityUrl = Uri.parse(
          'https://photon.komoot.io/api/?q=${Uri.encodeComponent(detectedCity)}&limit=1',
        );
        final response =
            await http.get(cityUrl).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final List features = data['features'] as List? ?? [];
          if (features.isNotEmpty) {
            final coords = features[0]['geometry']['coordinates'] as List;
            final lon = (coords[0] as num).toDouble();
            final lat = (coords[1] as num).toDouble();
            final center = LatLng(lat, lon);

            final region = CampusRegion(
              university: clean,
              center: center,
              radiusMeters: 800.0,
              defaultZoom: 15.0,
              isDynamicallyResolved: true,
            );
            _dynamicRegions[clean.toLowerCase().trim()] = region;
            debugPrint('Resolved city "$detectedCity" for campus "$clean" at ($lat, $lon)');
            return region;
          }
        }
      } catch (_) {}
    }

    // 5. Fallback region: use user GPS or detected city center, NEVER Stanford!
    final fallback = _defaultFallbackRegion(clean, userGpsHint);
    _dynamicRegions[clean.toLowerCase().trim()] = fallback;
    return fallback;
  }

  /// Extracts known city/district names from an input string
  static String? _extractCity(String text) {
    final lower = text.toLowerCase();
    const cities = [
      'rajkot',
      'nadiad',
      'ahmedabad',
      'vadodara',
      'surat',
      'gandhinagar',
      'anand',
      'bhavnagar',
      'jamnagar',
      'mumbai',
      'delhi',
      'pune',
      'bangalore',
      'bengaluru',
      'hyderabad',
      'chennai',
      'kolkata',
      'jaipur',
      'chandigarh',
      'lucknow',
      'indore',
      'bhopal',
      'london',
      'oxford',
      'cambridge',
      'boston',
      'toronto',
      'vancouver',
      'sydney',
      'melbourne',
    ];

    for (final city in cities) {
      if (lower.contains(city)) {
        return city;
      }
    }
    return null;
  }

  static CampusRegion _defaultFallbackRegion(
    String university,
    LatLng? userGpsHint,
  ) {
    // If user explicitly asked for Stanford, center on Stanford
    if (university.toLowerCase().contains('stanford')) {
      const center = LatLng(37.4275, -122.1697);
      return CampusRegion(
        university: university,
        center: center,
        radiusMeters: 700.0,
        isDynamicallyResolved: true,
      );
    }

    // Prioritize user GPS hint (real device location)
    if (userGpsHint != null) {
      return CampusRegion(
        university: university,
        center: userGpsHint,
        radiusMeters: 600.0,
        isDynamicallyResolved: true,
      );
    }

    // Check if a city is in the university name
    final city = _extractCity(university);
    if (city == 'rajkot') {
      const center = LatLng(22.3039, 70.8022);
      return CampusRegion(
        university: university,
        center: center,
        radiusMeters: 800.0,
        isDynamicallyResolved: true,
      );
    }

    // Neutral default center (never California unless specified)
    const center = LatLng(22.3039, 70.8022);
    return CampusRegion(
      university: university,
      center: center,
      radiusMeters: 700.0,
      isDynamicallyResolved: true,
    );
  }
}
