import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationPermissionService {
  static const String _permissionCheckedKey = 'location_permission_checked';
  static bool _isPermissionChecking = false;

  /// Check if the app has asked for permission before
  static Future<bool> hasCheckedForPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionCheckedKey) ?? false;
  }

  /// Mark that we've checked for permission
  static Future<void> markPermissionChecked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionCheckedKey, true);
  }

  /// Reset the permission check status (for testing)
  static Future<void> resetPermissionCheck() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionCheckedKey, false);
  }

  /// Check if the app has location permission
  static Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Check and request location permission on app start
  static Future<bool> checkAndRequestLocationPermission(
    BuildContext context,
  ) async {
    if (_isPermissionChecking) return false;
    _isPermissionChecking = true;

    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          _showLocationServiceDisabledDialog(context);
        }
        _isPermissionChecking = false;
        return false;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          _isPermissionChecking = false;
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Show settings dialog
        if (context.mounted) {
          _showPermissionDeniedForeverDialog(context);
        }
        _isPermissionChecking = false;
        return false;
      }

      // Mark that we've checked for permission
      await markPermissionChecked();
      _isPermissionChecking = false;
      return true;
    } catch (e) {
      _isPermissionChecking = false;
      return false;
    }
  }

  /// Show dialog when location services are disabled
  static void _showLocationServiceDisabledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'Please enable location services in your device settings to use location features in this app.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  /// Show dialog when permission is permanently denied
  static void _showPermissionDeniedForeverDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Location permission is required for this app to work properly. '
            'Please go to app settings and enable location permission.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }
}
