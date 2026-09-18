import 'package:flutter_map/flutter_map.dart';
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

  const CampusRegion({
    required this.university,
    required this.center,
    required this.bounds,
    this.minZoom = 14.5,
    this.maxZoom = 18.5,
    this.defaultZoom = 16.0,
    this.landmarks = const [],
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

  static CampusRegion? getRegion(String university) {
    for (final entry in _regions.entries) {
      if (entry.key.toLowerCase().trim() == university.toLowerCase().trim()) {
        return entry.value;
      }
    }

    return null;
  }
}
