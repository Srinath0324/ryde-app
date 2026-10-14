import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../services/map_service.dart';

class RydeMapWidget extends StatefulWidget {
  final bool showUserLocation;
  final Function(MapboxMap)? onMapCreated;
  final Function(CameraOptions)? onCameraChanged;
  final Function(Point)? onMapClick;
  final CameraOptions? initialCameraPosition;
  final Widget? child;

  const RydeMapWidget({
    super.key,
    this.showUserLocation = true,
    this.onMapCreated,
    this.onCameraChanged,
    this.onMapClick,
    this.initialCameraPosition,
    this.child,
  });

  @override
  State<RydeMapWidget> createState() => _RydeMapWidgetState();
}

class _RydeMapWidgetState extends State<RydeMapWidget> {
  MapboxMap? _mapboxMap;
  String? _styleUrl;
  CameraOptions? _initialCameraPosition;
  bool _isMapReady = false;
  StreamSubscription<geo.Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _styleUrl = MapService.styleUrl;
    _loadInitialPosition();
  }

  @override
  void dispose() {
    // Cancel location subscription when widget is disposed
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialPosition() async {
    if (widget.initialCameraPosition != null) {
      _initialCameraPosition = widget.initialCameraPosition;
    } else {
      _initialCameraPosition = await MapService.getInitialCameraOptions();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;

    if (widget.showUserLocation) {
      try {
        // Use the improved location puck implementation
        MapService.setupLocationPuck(mapboxMap);

        // Start location updates for real-time tracking
        _locationSubscription = MapService.startLocationUpdates(
          mapboxMap,
          _onLocationUpdate,
        );
      } catch (e) {
        debugPrint('Error setting up location tracking: $e');
      }
    }

    // Set up map click listener
    if (widget.onMapClick != null) {
      _setupMapClickListener(mapboxMap);
    }

    setState(() {
      _isMapReady = true;
    });

    if (widget.onMapCreated != null) {
      widget.onMapCreated!(mapboxMap);
    }
  }

  // Handle location updates
  void _onLocationUpdate(geo.Position position) {
    // This will be called whenever location changes
    // Each screen can override onMapCreated to get the mapboxMap instance
    // and implement their own location change handling if needed
  }

  // Set up a listener for map click events
  void _setupMapClickListener(MapboxMap mapboxMap) {
    // We'll implement this using a simple tap gesture detector
    // wrapped around the map in the build method
  }

  // Handle map tap by converting screen coordinates to map coordinates
  void _handleMapTap(TapPosition position) async {
    try {
      if (_mapboxMap != null && widget.onMapClick != null) {
        // Convert tap position to screen coordinate
        final screenPoint = ScreenCoordinate(
          x: position.global.dx,
          y: position.global.dy,
        );

        // Convert screen coordinate to map coordinate
        final point = await _mapboxMap!.coordinateForPixel(screenPoint);

        // Call the provided callback
        widget.onMapClick!(point);
      }
    } catch (e) {
      debugPrint('Error handling map tap: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialCameraPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final mapWidget = MapWidget(
      key: const ValueKey('mapWidget'),
      styleUri: _styleUrl ?? "mapbox://styles/mapbox/streets-v12",
      cameraOptions: _initialCameraPosition!,
      onMapCreated: _onMapCreated,
    );

    return Stack(
      children: [
        // Wrap map in GestureDetector if we have a click handler
        widget.onMapClick != null
            ? GestureDetector(
              onTapUp:
                  (details) => _handleMapTap(
                    TapPosition(
                      global: details.globalPosition,
                      relative: details.localPosition,
                    ),
                  ),
              child: mapWidget,
            )
            : mapWidget,

        // Child widget overlay if provided
        if (_isMapReady && widget.child != null) widget.child!,
      ],
    );
  }
}

// Helper class for tap position
class TapPosition {
  final Offset global;
  final Offset relative;

  TapPosition({required this.global, required this.relative});
}
