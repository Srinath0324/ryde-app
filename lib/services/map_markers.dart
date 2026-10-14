import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapMarkers {
  // Cache for marker references
  static Map<String, String> _markerIds = {};

  /// Add a teardrop marker to the map using Circle + Symbol approach
  static Future<String?> addTeardropMarker({
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

      // Create a GeoJSON source with the marker position
      final pointData = {
        'type': 'Feature',
        'properties': {'name': markerName ?? pointId},
        'geometry': {
          'type': 'Point',
          'coordinates': [position.lng, position.lat],
        },
      };

      // Try to remove existing layers and source if they exist
      try {
        if (await mapboxMap.style.styleLayerExists('${pointId}-circle')) {
          await mapboxMap.style.removeStyleLayer('${pointId}-circle');
        }
        if (await mapboxMap.style.styleSourceExists(pointId)) {
          await mapboxMap.style.removeStyleSource(pointId);
        }
      } catch (e) {
        // Ignore errors if elements don't exist yet
      }

      // Add source for the marker
      await mapboxMap.style.addSource(
        GeoJsonSource(id: pointId, data: jsonEncode(pointData)),
      );

      // Add a circle layer for the teardrop base
      await mapboxMap.style.addLayer(
        CircleLayer(
          id: '${pointId}-circle',
          sourceId: pointId,
          circleRadius: 15,
          circleColor: color.value,
          circleStrokeWidth: 2,
          circleStrokeColor: Colors.white.value,
        ),
      );

      // Store the marker ID for later reference
      _markerIds[pointId] = pointId;

      // Animate camera to marker position if requested
      if (animate) {
        await mapboxMap.flyTo(
          CameraOptions(center: Point(coordinates: position), zoom: 15.0),
          MapAnimationOptions(duration: 1000, startDelay: 0),
        );
      }

      return pointId;
    } catch (e) {
      debugPrint('Error adding teardrop marker: $e');
      return null;
    }
  }

  /// Remove a marker from the map
  static Future<bool> removeMarker(MapboxMap mapboxMap, String markerId) async {
    try {
      if (await mapboxMap.style.styleLayerExists('${markerId}-circle')) {
        await mapboxMap.style.removeStyleLayer('${markerId}-circle');
      }
      if (await mapboxMap.style.styleSourceExists(markerId)) {
        await mapboxMap.style.removeStyleSource(markerId);
      }

      // Remove from our tracking
      _markerIds.remove(markerId);

      return true;
    } catch (e) {
      debugPrint('Error removing marker: $e');
      return false;
    }
  }

  /// Fit map view to show both origin and destination markers with proper zoom
  static Future<void> fitMapToShowRoute({
    required MapboxMap mapboxMap,
    required Position origin,
    required Position destination,
  }) async {
    try {
      // Calculate bearing between points
      final bearing = _calculateBearing(origin, destination);

      // Calculate midpoint between origin and destination
      final midLng = (origin.lng + destination.lng) / 2;
      final midLat = (origin.lat + destination.lat) / 2;

      // Calculate distance between points in degrees (rough approximation)
      final lngDiff = (origin.lng - destination.lng).abs();
      final latDiff = (origin.lat - destination.lat).abs();

      // Choose appropriate zoom level based on distance
      // This is a simplistic approach - real implementations would be more sophisticated
      double zoom = 14.0; // Default zoom
      final distance = lngDiff + latDiff; // Simple distance metric

      if (distance > 0.1) zoom = 13.0;
      if (distance > 0.2) zoom = 12.0;
      if (distance > 0.3) zoom = 11.0;
      if (distance > 0.4) zoom = 10.0;
      if (distance > 0.6) zoom = 9.0;
      if (distance > 1.0) zoom = 8.0;

      // Create camera options to fit the route
      final cameraOptions = CameraOptions(
        center: Point(coordinates: Position(midLng, midLat)),
        zoom: zoom,
        bearing: bearing,
        pitch: 0.0, // No pitch for 2D view
      );

      // Animate to the new camera position
      await mapboxMap.flyTo(
        cameraOptions,
        MapAnimationOptions(duration: 1000, startDelay: 0),
      );
    } catch (e) {
      debugPrint('Error fitting map to show route: $e');
    }
  }

  /// Add a route line to the map
  static Future<String> addRoute(
    MapboxMap mapboxMap,
    List<Position> coordinates,
  ) async {
    // Generate a unique ID for this route
    final String routeId = 'route-${DateTime.now().millisecondsSinceEpoch}';
    final String routeLayerId = '$routeId-route';
    final String routeCasingLayerId = '$routeId-casing';

    try {
      // Create the GeoJSON for the route
      final geojson = {
        'type': 'Feature',
        'properties': {},
        'geometry': {
          'type': 'LineString',
          'coordinates': coordinates.map((pos) => [pos.lng, pos.lat]).toList(),
        },
      };

      // Add the GeoJSON source to the map
      await mapboxMap.style.addSource(
        GeoJsonSource(id: routeId, data: jsonEncode(geojson)),
      );

      // Add a casing layer for the route (creates a border/outline)
      await mapboxMap.style.addLayer(
        LineLayer(
          id: routeCasingLayerId,
          sourceId: routeId,
          lineColor: Colors.blue.shade800.value,
          lineWidth: 8.0,
          lineOpacity: 0.7,
        ),
      );

      // Add the main route layer
      await mapboxMap.style.addLayer(
        LineLayer(
          id: routeLayerId,
          sourceId: routeId,
          lineColor: Colors.blue.value,
          lineWidth: 4.0,
          lineOpacity: 0.9,
        ),
      );

      return routeId;
    } catch (e) {
      debugPrint('Error adding route: $e');
      return '';
    }
  }

  /// Remove a route from the map
  static Future<void> removeRoute(MapboxMap mapboxMap, String routeId) async {
    try {
      final routeLayerId = '$routeId-route';
      final routeCasingLayerId = '$routeId-casing';

      // Remove the layers first, then the source
      if (await mapboxMap.style.styleLayerExists(routeLayerId)) {
        await mapboxMap.style.removeStyleLayer(routeLayerId);
      }

      if (await mapboxMap.style.styleLayerExists(routeCasingLayerId)) {
        await mapboxMap.style.removeStyleLayer(routeCasingLayerId);
      }

      if (await mapboxMap.style.styleSourceExists(routeId)) {
        await mapboxMap.style.removeStyleSource(routeId);
      }
    } catch (e) {
      debugPrint('Error removing route: $e');
    }
  }

  /// Calculate bearing angle between two positions
  static double _calculateBearing(Position start, Position end) {
    final startLat = start.lat * (math.pi / 180);
    final startLng = start.lng * (math.pi / 180);
    final endLat = end.lat * (math.pi / 180);
    final endLng = end.lng * (math.pi / 180);

    final y = math.sin(endLng - startLng) * math.cos(endLat);
    final x =
        math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(endLng - startLng);

    var bearing = math.atan2(y, x) * (180 / math.pi);
    if (bearing < 0) bearing += 360;

    return bearing;
  }
}
