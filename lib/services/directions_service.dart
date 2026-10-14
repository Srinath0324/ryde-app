import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DirectionsService {
  static final String? _accessToken = dotenv.env['MAPBOX_PUBLIC_TOKEN'];
  static const String _endpoint =
      'https://api.mapbox.com/directions/v5/mapbox/driving';

  // Cache for vehicle images to avoid reloading
  static final Map<String, Uint8List> _vehicleImageCache = {};

  // Cache for annotation managers
  static PointAnnotationManager? _vehicleAnnotationManager;

  // Track active routes and layers for proper cleanup
  static final Set<String> _activeRouteLayers = {};
  static final Set<String> _activeSources = {};

  // Track active vehicle annotations for cleanup
  static final Set<PointAnnotation> _activeVehicleAnnotations = {};

  /// Get a route between coordinates
  static Future<Map<String, dynamic>> getRoute(
    Position origin,
    Position destination,
  ) async {
    if (_accessToken == null) {
      throw Exception('Mapbox access token not found');
    }

    final coordinates =
        '${origin.lng},${origin.lat};${destination.lng},${destination.lat}';
    final url =
        '$_endpoint/$coordinates?geometries=geojson&overview=full&access_token=$_accessToken';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['routes'] != null && data['routes'].length > 0) {
        final route = data['routes'][0];

        return {
          'routes': data['routes'],
          'geometry': route['geometry'],
          'duration': route['duration'],
          'distance': route['distance'],
        };
      } else {
        throw Exception('No route found between the coordinates');
      }
    } else {
      throw Exception('Failed to get directions: ${response.statusCode}');
    }
  }

  /// Get directions between coordinates with detailed response
  static Future<Map<String, dynamic>> getDirections(
    num startLng,
    num startLat,
    num endLng,
    num endLat,
  ) async {
    if (_accessToken == null) {
      throw Exception('Mapbox access token not found');
    }

    final coordinates = '$startLng,$startLat;$endLng,$endLat';
    final url =
        '$_endpoint/$coordinates?geometries=geojson&overview=full&access_token=$_accessToken';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];

        return {
          'routes': data['routes'],
          'geometry': route['geometry'],
          'duration': route['duration'], // in seconds
          'distance': route['distance'], // in meters
        };
      } else {
        throw Exception('No route found between the coordinates');
      }
    } else {
      throw Exception('Failed to get directions: ${response.statusCode}');
    }
  }

  /// Draw a route on the map - routes are drawn BEFORE vehicle markers to ensure proper layering
  static Future<String> drawRoute(
    MapboxMap mapboxMap,
    Map<String, dynamic> geometry,
  ) async {
    // Generate unique source and layer IDs
    final String sourceId =
        'route-source-${DateTime.now().millisecondsSinceEpoch}';
    final String routeLayerId = '$sourceId-route';
    final String casingLayerId = '$sourceId-casing';

    // Create a GeoJSON source with the route geometry
    final geojson = {'type': 'Feature', 'properties': {}, 'geometry': geometry};

    try {
      // Clear ALL previously drawn routes to prevent accumulation
      await clearAllRoutes(mapboxMap);

      // Add source
      await mapboxMap.style.addSource(
        GeoJsonSource(id: sourceId, data: jsonEncode(geojson)),
      );
      _activeSources.add(sourceId);

      // Add casing layer first (outline/border)
      await mapboxMap.style.addLayer(
        LineLayer(
          id: casingLayerId,
          sourceId: sourceId,
          lineColor: Colors.blue.shade800.value,
          lineWidth: 8.0,
          lineOpacity: 0.7,
        ),
      );
      _activeRouteLayers.add(casingLayerId);

      // Add main route layer on top of casing
      await mapboxMap.style.addLayer(
        LineLayer(
          id: routeLayerId,
          sourceId: sourceId,
          lineColor: Colors.blue.value,
          lineWidth: 4.0,
          lineOpacity: 0.9,
        ),
      );
      _activeRouteLayers.add(routeLayerId);

      print(
        '✅ Route drawn - source: $sourceId (vehicle markers will be added on top)',
      );
      return sourceId;
    } catch (e) {
      print('❌ Error drawing route: $e');
      return '';
    }
  }

  /// Load vehicle image bytes for annotation
  static Future<Uint8List> _getVehicleImageBytes(String vehicleType) async {
    try {
      // Get vehicle image asset path
      String imagePath = _getVehicleImagePath(vehicleType);

      // Load the image from assets
      final imageBytes = await _loadAssetImage(imagePath);

      print('✅ Vehicle image loaded: $vehicleType');
      return imageBytes;
    } catch (e) {
      print('❌ Error loading vehicle image: $e');
      throw Exception('Failed to load vehicle image: $e');
    }
  }

  /// Clear all active routes from the map
  static Future<void> clearAllRoutes(MapboxMap mapboxMap) async {
    try {
      print(
        '🧹 Clearing ${_activeRouteLayers.length} route layers and ${_activeSources.length} sources',
      );

      // Remove all tracked route layers
      for (final layerId in List.from(_activeRouteLayers)) {
        try {
          if (await mapboxMap.style.styleLayerExists(layerId)) {
            await mapboxMap.style.removeStyleLayer(layerId);
            print('🗑️ Removed layer: $layerId');
          }
        } catch (e) {
          print('⚠️ Error removing layer $layerId: $e');
        }
      }
      _activeRouteLayers.clear();

      // Remove all tracked sources
      for (final sourceId in List.from(_activeSources)) {
        try {
          if (await mapboxMap.style.styleSourceExists(sourceId)) {
            await mapboxMap.style.removeStyleSource(sourceId);
            print('🗑️ Removed source: $sourceId');
          }
        } catch (e) {
          print('⚠️ Error removing source $sourceId: $e');
        }
      }
      _activeSources.clear();

      print('✅ All routes cleared successfully');
    } catch (e) {
      print('❌ Error clearing routes: $e');
    }
  }

  /// Clear all vehicle markers to prevent duplicates
  static Future<void> clearAllVehicleMarkers() async {
    try {
      if (_vehicleAnnotationManager != null) {
        // Remove all tracked annotations
        for (final annotation in List.from(_activeVehicleAnnotations)) {
          try {
            await _vehicleAnnotationManager!.delete(annotation);
          } catch (e) {
            print('⚠️ Error removing individual annotation: $e');
          }
        }
        _activeVehicleAnnotations.clear();
        print('✅ All vehicle markers cleared');
      } else {
        print('⚠️ Cannot clear markers: annotation manager is null');
      }
    } catch (e) {
      print('❌ Error clearing vehicle markers: $e');
      // Reset manager if it's become invalid
      _vehicleAnnotationManager = null;
    }
  }

  /// Trim route to remove traveled path and show only remaining route
  static Future<void> trimRouteToPosition(
    MapboxMap mapboxMap,
    String sourceId,
    List<Position> originalRoute,
    Position currentPosition,
    int nearestIndex,
  ) async {
    try {
      if (nearestIndex <= 0 || nearestIndex >= originalRoute.length) {
        return; // No trimming needed
      }

      // Create trimmed route from current position onwards
      final trimmedRoute = [
        currentPosition,
        ...originalRoute.sublist(nearestIndex + 1),
      ];

      if (trimmedRoute.length < 2) {
        return; // Need at least 2 points for a route
      }

      // Create updated geometry
      final trimmedGeometry = {
        'type': 'LineString',
        'coordinates': trimmedRoute.map((pos) => [pos.lng, pos.lat]).toList(),
      };

      final geojson = {
        'type': 'Feature',
        'properties': {},
        'geometry': trimmedGeometry,
      };

      // Update the existing source with trimmed route by removing and re-adding
      if (await mapboxMap.style.styleSourceExists(sourceId)) {
        // Remove old source
        await mapboxMap.style.removeStyleSource(sourceId);

        // Add updated source
        await mapboxMap.style.addSource(
          GeoJsonSource(id: sourceId, data: jsonEncode(geojson)),
        );

        print('✂️ Route trimmed successfully');
      } else {
        print('⚠️ Source $sourceId does not exist for trimming');
      }
    } catch (e) {
      print('❌ Error trimming route: $e');
    }
  }

  /// Add marker for a location point
  static Future<String> addMarker(
    MapboxMap mapboxMap,
    Position position,
    Color color, {
    String? markerId,
  }) async {
    final pointId =
        markerId ?? 'point-${DateTime.now().millisecondsSinceEpoch}';

    // Create GeoJSON for point
    final pointGeoJson = {
      'type': 'Feature',
      'properties': {},
      'geometry': {
        'type': 'Point',
        'coordinates': [position.lng, position.lat],
      },
    };

    try {
      // Add source for point
      await mapboxMap.style.addSource(
        GeoJsonSource(id: pointId, data: jsonEncode(pointGeoJson)),
      );

      // Add circle layer for point
      await mapboxMap.style.addLayer(
        CircleLayer(
          id: '${pointId}-circle',
          sourceId: pointId,
          circleColor: color.value,
          circleRadius: 10.0,
          circleStrokeColor: Colors.white.value,
          circleStrokeWidth: 2.0,
        ),
      );

      return pointId;
    } catch (e) {
      print('Error adding marker: $e');
      return '';
    }
  }

  /// Load image from assets and convert to bytes
  static Future<Uint8List> _loadAssetImage(String assetPath) async {
    try {
      if (_vehicleImageCache.containsKey(assetPath)) {
        return _vehicleImageCache[assetPath]!;
      }

      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();

      // Cache the image for future use
      _vehicleImageCache[assetPath] = bytes;

      return bytes;
    } catch (e) {
      print('Error loading asset image $assetPath: $e');
      throw Exception('Failed to load vehicle image: $assetPath');
    }
  }

  /// Create or get vehicle annotation manager
  static Future<PointAnnotationManager> _getVehicleAnnotationManager(
    MapboxMap mapboxMap,
  ) async {
    // If we don't have a manager, create a new one
    if (_vehicleAnnotationManager == null) {
      try {
        _vehicleAnnotationManager =
            await mapboxMap.annotations.createPointAnnotationManager();
        print('✅ New vehicle annotation manager created');
        return _vehicleAnnotationManager!;
      } catch (e) {
        print('❌ Failed to create annotation manager: $e');
        throw Exception('Failed to create annotation manager: $e');
      }
    }

    return _vehicleAnnotationManager!;
  }

  /// Add vehicle marker using registered image for proper layering
  /// This MUST be called AFTER drawRoute() to ensure marker appears on top
  static Future<PointAnnotation?> addVehicleMarker(
    MapboxMap mapboxMap,
    Position position,
    String vehicleType, {
    String? markerId,
    double? heading,
  }) async {
    try {
      print(
        '🚗 Adding vehicle marker for $vehicleType at ${position.lat}, ${position.lng}',
      );

      // STEP 1: Clear any existing vehicle markers to prevent duplicates
      await clearAllVehicleMarkers();

      // STEP 2: Load vehicle image bytes
      final imageBytes = await _getVehicleImageBytes(vehicleType);

      // STEP 3: Get annotation manager
      final annotationManager = await _getVehicleAnnotationManager(mapboxMap);

      // STEP 4: Create point annotation with image bytes
      final options = PointAnnotationOptions(
        geometry: Point(coordinates: position),
        image: imageBytes, // Use image bytes directly
        iconSize: 0.3, // Good size for visibility
        iconRotate: heading ?? 0.0,
        iconAnchor: IconAnchor.CENTER,
      );

      // STEP 5: Create the annotation
      final annotation = await annotationManager.create(options);

      // STEP 6: Track the annotation for cleanup
      _activeVehicleAnnotations.add(annotation);

      print('✅ Vehicle marker created with proper layering for $vehicleType');
      return annotation;
    } catch (e) {
      print('❌ Error adding vehicle marker: $e');
      // Reset manager if it fails
      _vehicleAnnotationManager = null;
      return null;
    }
  }

  /// Update vehicle marker position with smooth animation
  static Future<void> updateVehicleMarkerPosition(
    PointAnnotation annotation,
    Position newPosition, {
    double? newHeading,
  }) async {
    try {
      // Update geometry
      annotation.geometry = Point(coordinates: newPosition);

      // Update rotation if heading is provided
      if (newHeading != null) {
        annotation.iconRotate = newHeading;
      }

      // Get annotation manager and update
      if (_vehicleAnnotationManager != null) {
        await _vehicleAnnotationManager!.update(annotation);
        print(
          '✅ Vehicle marker position updated to ${newPosition.lat}, ${newPosition.lng}',
        );
      } else {
        print('⚠️ Cannot update marker: annotation manager is null');
      }
    } catch (e) {
      print('❌ Error updating vehicle marker position: $e');
      // Reset manager if it's become invalid
      _vehicleAnnotationManager = null;
    }
  }

  /// Remove vehicle marker
  static Future<void> removeVehicleMarker(PointAnnotation annotation) async {
    try {
      if (_vehicleAnnotationManager != null) {
        await _vehicleAnnotationManager!.delete(annotation);
        _activeVehicleAnnotations.remove(annotation);
        print('✅ Vehicle marker removed');
      } else {
        print('⚠️ Cannot remove marker: annotation manager is null');
      }
    } catch (e) {
      print('❌ Error removing vehicle marker: $e');
      // Reset manager if it's become invalid
      _vehicleAnnotationManager = null;
    }
  }

  /// Reset annotation manager and clear all state - call this when map is recreated
  static void resetAnnotationManager() {
    _vehicleAnnotationManager = null;
    _activeRouteLayers.clear();
    _activeSources.clear();
    _activeVehicleAnnotations.clear();
    print('🔄 All DirectionsService state reset');
  }

  /// Get vehicle image asset path
  static String _getVehicleImagePath(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'car':
        return 'assets/images/car.png';
      case 'bike':
        return 'assets/images/bike.png';
      case 'auto':
        return 'assets/images/auto.png';
      case 'e_rickshaw':
        return 'assets/images/e_rickshaw.png';
      default:
        return 'assets/images/car.png';
    }
  }

  /// Remove source and layer from map
  static Future<void> removeSource(MapboxMap mapboxMap, String sourceId) async {
    try {
      // Remove regular marker layer
      final layerId = '${sourceId}-circle';
      if (await mapboxMap.style.styleLayerExists(layerId)) {
        await mapboxMap.style.removeStyleLayer(layerId);
      }

      // Remove route layers
      final routeLayerId = '${sourceId}-route';
      if (await mapboxMap.style.styleLayerExists(routeLayerId)) {
        await mapboxMap.style.removeStyleLayer(routeLayerId);
        _activeRouteLayers.remove(routeLayerId);
      }

      final casingLayerId = '${sourceId}-casing';
      if (await mapboxMap.style.styleLayerExists(casingLayerId)) {
        await mapboxMap.style.removeStyleLayer(casingLayerId);
        _activeRouteLayers.remove(casingLayerId);
      }

      // Remove the source
      if (await mapboxMap.style.styleSourceExists(sourceId)) {
        await mapboxMap.style.removeStyleSource(sourceId);
        _activeSources.remove(sourceId);
      }
    } catch (e) {
      print('Error removing source: $e');
    }
  }
}
