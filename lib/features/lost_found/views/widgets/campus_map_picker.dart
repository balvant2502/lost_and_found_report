import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/campus_bounds.dart';
import '../../../../core/utils/geolocation_service.dart';

class CampusMapPicker extends StatefulWidget {
  final String university;
  final LatLng? initialPosition;
  final bool isLost;
  final Function(LatLng position, String placeName) onLocationSelected;

  const CampusMapPicker({
    super.key,
    required this.university,
    this.initialPosition,
    required this.isLost,
    required this.onLocationSelected,
  });

  @override
  State<CampusMapPicker> createState() => _CampusMapPickerState();
}

class _CampusMapPickerState extends State<CampusMapPicker> {
  late final MapController _mapController;
  late final CampusRegion? _region;

  LatLng? _selectedPosition;
  String _resolvedName = '';
  bool _isResolving = false;
  bool _isLocating = false;
  int _selectionRequest = 0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _region = CampusBounds.getRegion(widget.university);

    final region = _region;
    final initial = region != null && widget.initialPosition != null
      ? region.clamp(widget.initialPosition!)
      : region?.center;

    if (initial != null) _updatePinPosition(initial);
  }

  void _updatePinPosition(LatLng position) async {
    if (_region == null) return;
    final request = ++_selectionRequest;
    final clamped = _region.clamp(position);
    setState(() {
      _selectedPosition = clamped;
      _isResolving = true;
    });

    final name = await GeolocationService.resolvePlaceName(clamped, _region);

    if (mounted && request == _selectionRequest) {
      setState(() {
        _resolvedName = name;
        _isResolving = false;
      });
      widget.onLocationSelected(clamped, name);
    }
  }

  void _locateUser() async {
    if (_region == null) return;
    setState(() => _isLocating = true);

    final result = await GeolocationService.getCurrentCampusLocation(_region);

    if (!mounted) return;
    setState(() => _isLocating = false);

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? 'Unable to determine GPS location.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (result.isInsideCampus && result.position != null) {
      _mapController.move(result.position!, _region.defaultZoom);
      _updatePinPosition(result.position!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pin placed at your current campus location.'),
          backgroundColor: AppTheme.foundColor,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // User is currently off campus
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your current GPS location is outside ${widget.university}. '
            'Please tap on the campus map to pinpoint the item.',
          ),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinColor = widget.isLost ? AppTheme.lostColor : AppTheme.foundColor;

    if (_region == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDBA74)),
        ),
        child: Text(
          'A campus map is not available for ${widget.university} yet. '
          'Please choose a supported university or ask an administrator to add its campus boundaries.',
          style: const TextStyle(color: Color(0xFF9A3412)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Campus Region Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Locked to ${widget.university} region',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Tap to pin',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Interactive Map
        Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedPosition ?? _region.center,
                  initialZoom: _region.defaultZoom,
                  minZoom: _region.minZoom,
                  maxZoom: _region.maxZoom,
                  cameraConstraint: CameraConstraint.contain(
                    bounds: _region.bounds,
                  ),
                  onTap: (tapPosition, point) {
                    _updatePinPosition(point);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.campus_found',
                  ),

                  // Campus boundary outline
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: [
                          LatLng(_region.bounds.south, _region.bounds.west),
                          LatLng(_region.bounds.north, _region.bounds.west),
                          LatLng(_region.bounds.north, _region.bounds.east),
                          LatLng(_region.bounds.south, _region.bounds.east),
                        ],
                        borderColor: AppTheme.primaryColor.withValues(alpha: 0.6),
                        borderStrokeWidth: 2,
                        color: AppTheme.primaryColor.withValues(alpha: 0.04),
                      ),
                    ],
                  ),

                  // Landmark markers
                  MarkerLayer(
                    markers: _region.landmarks.map((landmark) {
                      return Marker(
                        point: landmark.position,
                        width: 70,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _updatePinPosition(landmark.position),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  landmark.name,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.apartment_rounded,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Active Pin Marker
                  if (_selectedPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedPosition!,
                          width: 48,
                          height: 48,
                          alignment: Alignment.topCenter,
                          child: Column(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 38,
                                color: pinColor,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black38,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Controls Overlay (Locate Me & Zoom)
              Positioned(
                bottom: 12,
                right: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'map_locate_user',
                      onPressed: _isLocating ? null : _locateUser,
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      child: _isLocating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded, size: 20),
                    ),
                    const SizedBox(height: 6),
                    FloatingActionButton.small(
                      heroTag: 'map_recenter',
                      onPressed: () {
                        _mapController.move(
                          _selectedPosition ?? _region.center,
                          _region.defaultZoom,
                        );
                      },
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF475569),
                      child: const Icon(Icons.center_focus_strong_rounded, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Selected Location Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            border: Border(
              left: BorderSide(color: Color(0xFFCBD5E1)),
              right: BorderSide(color: Color(0xFFCBD5E1)),
              bottom: BorderSide(color: Color(0xFFCBD5E1)),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: pinColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pin_drop_rounded,
                  color: pinColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Selected Campus Spot',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (_isResolving) ...[
                          const SizedBox(width: 6),
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _resolvedName.isNotEmpty
                          ? _resolvedName
                          : 'Resolving campus location...',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_selectedPosition != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${_selectedPosition!.latitude.toStringAsFixed(5)}, ${_selectedPosition!.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
