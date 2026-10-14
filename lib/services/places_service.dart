import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:flutter/material.dart';

class PlacesService {
  static final String? _accessToken = dotenv.env['MAPBOX_PUBLIC_TOKEN'];
  static const String _endpoint =
      'https://api.mapbox.com/geocoding/v5/mapbox.places';

  /// Get location suggestions as user types
  /// proximityLongitude and proximityLatitude are used to bias results to user's current location
  static Future<List<Map<String, dynamic>>> getSuggestions(
    String query, {
    double? proximityLongitude,
    double? proximityLatitude,
    int limit = 5,
  }) async {
    if (_accessToken == null) {
      throw Exception('Mapbox access token not found');
    }

    if (query.isEmpty) {
      return [];
    }

    // Build URL with proximity if available
    final encodedQuery = Uri.encodeComponent(query);
    String url =
        '$_endpoint/$encodedQuery.json?access_token=$_accessToken&limit=$limit';

    // Add proximity parameter if available
    if (proximityLongitude != null && proximityLatitude != null) {
      url += '&proximity=$proximityLongitude,$proximityLatitude';
    }

    // Add types parameter to filter results
    url += '&types=address,place,poi,neighborhood,locality';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['features'] == null || data['features'].isEmpty) {
          return [];
        }

        // Convert features to a list of suggestion maps
        final List<Map<String, dynamic>> suggestions = [];

        for (var feature in data['features']) {
          final coordinates = feature['geometry']['coordinates'];

          suggestions.add({
            'placeName': feature['place_name'],
            'text': feature['text'],
            'coordinates': Position(coordinates[0], coordinates[1]),
            'id': feature['id'],
            'properties': feature['properties'] ?? {},
          });
        }

        return suggestions;
      } else {
        throw Exception('Failed to get suggestions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting suggestions: $e');
      return [];
    }
  }

  /// Get the user's current location and reverse geocode it
  static Future<Map<String, dynamic>> getCurrentLocationAddress() async {
    try {
      // Get current position
      final geo.Position position = await geo.Geolocator.getCurrentPosition();

      // Reverse geocode to get address
      if (_accessToken == null) {
        throw Exception('Mapbox access token not found');
      }

      final url =
          '$_endpoint/${position.longitude},${position.latitude}.json?access_token=$_accessToken&limit=1';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0];
          final coordinates = feature['geometry']['coordinates'];

          return {
            'placeName': feature['place_name'],
            'text': feature['text'],
            'coordinates': Position(coordinates[0], coordinates[1]),
            'position': position,
          };
        } else {
          throw Exception('No address found for the current location');
        }
      } else {
        throw Exception('Failed to reverse geocode: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting current location address: $e');
      rethrow;
    }
  }
}
