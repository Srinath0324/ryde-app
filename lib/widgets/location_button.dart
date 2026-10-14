import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../services/map_service.dart';

class LocationButton extends StatelessWidget {
  final MapboxMap? mapboxMap;
  final double size;
  final double iconSize;
  final EdgeInsetsGeometry? margin;
  final Function()? onLocationButtonPressed;
  final Function(bool)? onLocationPermissionResult;

  const LocationButton({
    Key? key,
    this.mapboxMap,
    this.size = 50.0,
    this.iconSize = 24.0,
    this.margin,
    this.onLocationButtonPressed,
    this.onLocationPermissionResult,
  }) : super(key: key);

  // Show location services disabled dialog
  Future<void> _showLocationServicesDisabledDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'Please enable location services to use this feature. Would you like to open settings now?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                MapService.openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // Show location permission denied dialog
  Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Please grant location permission to use this feature.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Grant Permission'),
              onPressed: () {
                Navigator.of(context).pop();
                _requestLocationPermission(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Show permanently denied dialog
  Future<void> _showPermissionPermanentlyDeniedDialog(
    BuildContext context,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Denied'),
          content: const Text(
            'Location permission is permanently denied. Please enable it in app settings.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                MapService.openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // Request location permission
  Future<void> _requestLocationPermission(BuildContext context) async {
    final permission = await MapService.requestLocationPermission();
    if (permission == geo.LocationPermission.denied) {
      if (context.mounted) {
        await _showPermissionDeniedDialog(context);
      }
    } else if (permission == geo.LocationPermission.deniedForever) {
      if (context.mounted) {
        await _showPermissionPermanentlyDeniedDialog(context);
      }
    } else {
      // Permission granted, try to get location
      if (context.mounted) {
        _moveToCurrentLocation(context);
      }
    }
  }

  // Move to current location
  Future<void> _moveToCurrentLocation(BuildContext context) async {
    try {
      if (mapboxMap != null) {
        await MapService.animateCameraToCurrentLocation(mapboxMap!);
      }

      // Notify about successful location
      if (onLocationPermissionResult != null) {
        onLocationPermissionResult!(true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Notify about failure
      if (onLocationPermissionResult != null) {
        onLocationPermissionResult!(false);
      }
    }
  }

  // Handle location button press with permission checks
  Future<void> _handleLocationRequest(BuildContext context) async {
    // Notify parent that location button was pressed
    if (onLocationButtonPressed != null) {
      onLocationButtonPressed!();
    }

    try {
      // Check if location services are enabled
      final serviceEnabled = await MapService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          await _showLocationServicesDisabledDialog(context);
        }
        return;
      }

      // Check current permission status
      final permissionStatus = await MapService.checkLocationPermission();

      if (permissionStatus == geo.LocationPermission.denied) {
        if (context.mounted) {
          await _requestLocationPermission(context);
        }
      } else if (permissionStatus == geo.LocationPermission.deniedForever) {
        if (context.mounted) {
          await _showPermissionPermanentlyDeniedDialog(context);
        }
      } else {
        // Permission already granted, move to current location
        if (context.mounted) {
          await _moveToCurrentLocation(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Notify about failure
      if (onLocationPermissionResult != null) {
        onLocationPermissionResult!(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: GestureDetector(
        onTap: () => _handleLocationRequest(context),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF0CC25F),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(Icons.my_location, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }
}
