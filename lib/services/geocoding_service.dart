import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class GeocodingService {
  static final String? _accessToken = dotenv.env['MAPBOX_PUBLIC_TOKEN'];
  static const String _endpoint =
      'https://api.mapbox.com/geocoding/v5/mapbox.places';

  /// Converts a location name to coordinates
  /// Returns a Map containing:
  /// - `coordinates`: Position object (lon, lat)
  /// - `placeName`: Formatted place name
  /// - `features`: List of all place features returned
  static Future<Map<String, dynamic>> geocode(String placeName) async {
    if (_accessToken == null) {
      throw Exception('Mapbox access token not found');
    }

    final encodedPlace = Uri.encodeComponent(placeName);
    final url =
        '$_endpoint/$encodedPlace.json?access_token=$_accessToken&limit=1';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['features'] != null && data['features'].length > 0) {
        final feature = data['features'][0];
        final coordinates = feature['geometry']['coordinates'];

        return {
          'coordinates': Position(coordinates[0], coordinates[1]),
          'placeName': feature['place_name'],
          'features': data['features'],
        };
      } else {
        throw Exception('No locations found for "$placeName"');
      }
    } else {
      throw Exception('Failed to geocode location: ${response.statusCode}');
    }
  }

  /// Converts coordinates to a location name (reverse geocoding)
  /// Returns a Map containing:
  /// - `placeName`: Formatted place name
  /// - `features`: List of all place features returned
  static Future<Map<String, dynamic>> reverseGeocode(
    double longitude,
    double latitude,
  ) async {
    if (_accessToken == null) {
      throw Exception('Mapbox access token not found');
    }

    final url =
        '$_endpoint/$longitude,$latitude.json?access_token=$_accessToken&limit=1';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['features'] != null && data['features'].length > 0) {
        final feature = data['features'][0];

        return {
          'placeName': feature['place_name'],
          'features': data['features'],
          'address': _formatAddress(data['features']),
        };
      } else {
        throw Exception('No address found for the given coordinates');
      }
    } else {
      throw Exception('Failed to reverse geocode: ${response.statusCode}');
    }
  }

  /// Helper function to format address from features
  static String _formatAddress(List features) {
    if (features.isEmpty) {
      return 'Unknown location';
    }

    // Get the first feature which is usually the most specific
    final mainFeature = features[0];

    // If place_name is available, use it directly
    if (mainFeature['place_name'] != null) {
      return mainFeature['place_name'];
    }

    // Otherwise, build address from context if available
    final List context = mainFeature['context'] ?? [];
    if (context.isNotEmpty) {
      return context.map((item) => item['text']).join(', ');
    }

    // Fallback to text if nothing else is available
    return mainFeature['text'] ?? 'Unknown location';
  }
}
