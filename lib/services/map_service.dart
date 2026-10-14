import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;

class MapService {
  static final MapService _instance = MapService._internal();
  static String? _accessToken;
  static String? _styleUrl;
  static bool _hasLocationPermission = false;

  // Add a constant for location puck customization
  static const Color locationPuckColor = Color(
    0xFF1A73E8,
  ); // Google Maps-like blue

  factory MapService() {
    return _instance;
  }

  MapService._internal();

  static Future<void> initialize() async {
    _accessToken = dotenv.env['MAPBOX_PUBLIC_TOKEN'];
    _styleUrl = dotenv.env['MAPBOX_STYLE_URL'];

    // Initialize MapBox options with access token
    if (_accessToken != null) {
      try {
        // Using setAccessToken if it's available
        MapboxOptions.setAccessToken(_accessToken!);
      } catch (e) {
        print('Warning: Could not set Mapbox access token: $e');
        print('Using fallback method to configure MapBox token...');
      }
    } else {
      throw Exception('MapBox access token not found in .env file');
    }
  }

  static String? get styleUrl => _styleUrl;

  static String? get accessToken => _accessToken;

  static void setLocationPermissionStatus(bool hasPermission) {
    _hasLocationPermission = hasPermission;
  }

  static bool get hasLocationPermission => _hasLocationPermission;

  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await geo.Geolocator.isLocationServiceEnabled();
  }

  // Check location permission status
  static Future<geo.LocationPermission> checkLocationPermission() async {
    return await geo.Geolocator.checkPermission();
  }

  // Open location settings
  static Future<bool> openLocationSettings() async {
    return await geo.Geolocator.openLocationSettings();
  }

  // Open app settings
  static Future<bool> openAppSettings() async {
    return await geo.Geolocator.openAppSettings();
  }

  // Request location permission
  static Future<geo.LocationPermission> requestLocationPermission() async {
    return await geo.Geolocator.requestPermission();
  }

  // Request location permission and return position
  static Future<geo.Position> getCurrentLocation() async {
    bool serviceEnabled;
    geo.LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return Future.error('Location services are disabled.');
    }

    permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        // Permissions are denied
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      // Permissions are permanently denied
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // Update permission status
    _hasLocationPermission = true;

    // When we reach here, permissions are granted and we can continue
    return await geo.Geolocator.getCurrentPosition();
  }

  // Get camera options centered on current location
  static Future<CameraOptions> getInitialCameraOptions() async {
    try {
      geo.Position position = await getCurrentLocation();
      return CameraOptions(
        center: Point(
          coordinates: Position(position.longitude, position.latitude),
        ),
        zoom: 15.0,
      );
    } catch (e) {
      // Default to a central location in case of error
      return CameraOptions(
        center: Point(
          coordinates: Position(77.63, 22.55), // Default center of India
        ),
        zoom: 5.0,
      );
    }
  }

  // Set up location puck on the map (replaced implementation)
  static void setupLocationPuck(MapboxMap mapboxMap) {
    try {
      // Configure a reliable, non-delayed location puck
      mapboxMap.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          showAccuracyRing: true,
          accuracyRingColor: locationPuckColor.withOpacity(0.1).value,
          accuracyRingBorderColor: locationPuckColor.withOpacity(0.3).value,
          pulsingEnabled: false, // Disable pulsing for reliability
          puckBearingEnabled: true, // Show heading when available
          locationPuck: LocationPuck(
            locationPuck2D: LocationPuck2D(
              topImage: null, // Using default
              bearingImage: null, // Using default
              shadowImage: null, // Using default
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error setting up location puck: $e');
    }
  }

  // Start continuous location updates for real-time tracking
  static StreamSubscription<geo.Position>? startLocationUpdates(
    MapboxMap mapboxMap,
    void Function(geo.Position) onLocationUpdate,
  ) {
    try {
      // Set up a high-accuracy, real-time location stream
      final Stream<geo.Position> positionStream = geo
          .Geolocator.getPositionStream(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          distanceFilter: 5, // Update if moved 5 meters
        ),
      );

      // Subscribe to location updates
      final subscription = positionStream.listen((geo.Position position) {
        // Update the map's location settings to reflect accuracy
        mapboxMap.location.updateSettings(
          LocationComponentSettings(
            enabled: true,
            showAccuracyRing: true,
            accuracyRingColor: locationPuckColor.withOpacity(0.1).value,
            accuracyRingBorderColor: locationPuckColor.withOpacity(0.3).value,
            // Accuracy radius based on the reported accuracy
            puckBearingEnabled: true,
          ),
        );

        // Call the provided callback with the new position
        onLocationUpdate(position);
      });

      return subscription;
    } catch (e) {
      debugPrint('Error starting location updates: $e');
      return null;
    }
  }

  // Add a custom location marker to the map
  static Future<String?> addLocationMarker({
    required MapboxMap mapboxMap,
    required Position position,
    required Color color,
    String? markerId,
    String? markerName,
    bool animate = false,
  }) async {
    try {
      // Generate a unique marker ID if not provided
      final String pointId =
          markerId ?? 'marker-${DateTime.now().millisecondsSinceEpoch}';

      // Create GeoJSON for the marker
      final pointData = {
        'type': 'Feature',
        'properties': {'name': markerName ?? pointId},
        'geometry': {
          'type': 'Point',
          'coordinates': [position.lng, position.lat],
        },
      };

      // Try to remove the marker if it already exists
      try {
        if (await mapboxMap.style.styleLayerExists('${pointId}-circle')) {
          await mapboxMap.style.removeStyleLayer('${pointId}-circle');
        }
        // Try to remove source even if we don't know if it exists
        await mapboxMap.style.removeStyleSource(pointId);
      } catch (e) {
        // Ignore errors if the marker doesn't exist yet
      }

      // Add source for the marker
      await mapboxMap.style.addSource(
        GeoJsonSource(id: pointId, data: jsonEncode(pointData)),
      );

      // Add the marker layer as a circle
      await mapboxMap.style.addLayer(
        CircleLayer(
          id: '${pointId}-circle',
          sourceId: pointId,
          circleColor: color.value,
          circleRadius: 12.0,
          circleStrokeColor: Colors.white.value,
          circleStrokeWidth: 3.0,
        ),
      );

      // Animate camera to marker position if requested
      if (animate) {
        await mapboxMap.flyTo(
          CameraOptions(center: Point(coordinates: position), zoom: 15.0),
          MapAnimationOptions(duration: 1000, startDelay: 0),
        );
      }

      return pointId;
    } catch (e) {
      debugPrint('Error adding marker: $e');
      return null;
    }
  }

  // Remove a marker from the map
  static Future<bool> removeMarker(MapboxMap mapboxMap, String markerId) async {
    try {
      if (await mapboxMap.style.styleLayerExists('${markerId}-circle')) {
        await mapboxMap.style.removeStyleLayer('${markerId}-circle');
      }
      // Try to remove source
      try {
        await mapboxMap.style.removeStyleSource(markerId);
      } catch (e) {
        // Ignore errors if source doesn't exist
      }
      return true;
    } catch (e) {
      debugPrint('Error removing marker: $e');
      return false;
    }
  }

  // Move camera to current location
  static Future<void> animateCameraToCurrentLocation(
    MapboxMap mapboxMap,
  ) async {
    try {
      final position = await getCurrentLocation();

      final cameraOptions = CameraOptions(
        center: Point(
          coordinates: Position(position.longitude, position.latitude),
        ),
        zoom: 16.0,
        bearing: 0,
        pitch: 0,
      );

      mapboxMap.flyTo(
        cameraOptions,
        MapAnimationOptions(duration: 1000, startDelay: 0),
      );
    } catch (e) {
      print('Error moving camera to current location: $e');
      rethrow;
    }
  }

  // Animate camera to specific position
  static Future<void> animateCameraToPosition(
    MapboxMap mapboxMap,
    Position position, {
    double zoom = 16.0,
  }) async {
    try {
      final cameraOptions = CameraOptions(
        center: Point(coordinates: position),
        zoom: zoom,
        bearing: 0,
        pitch: 0,
      );

      mapboxMap.flyTo(
        cameraOptions,
        MapAnimationOptions(duration: 1000, startDelay: 0),
      );
    } catch (e) {
      print('Error moving camera to position: $e');
    }
  }

  // Convert a LatLng to Point for MapBox
  static Map<String, dynamic> latLngToPoint(double lat, double lng) {
    return Point(coordinates: Position(lng, lat)).toJson();
  }
}
