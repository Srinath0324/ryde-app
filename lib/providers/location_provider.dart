import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../services/location_permission_service.dart';
import '../services/map_service.dart';
import '../services/places_service.dart';

/// Provider for handling location-related state and functions
class LocationProvider extends ChangeNotifier with WidgetsBindingObserver {
  geo.Position? _currentPosition;
  String? _currentAddress;
  bool _hasLocationPermission = false;
  bool _isLocationServiceEnabled = false;
  bool _isLoadingLocation = false;
  bool _wasPermissionPreviouslyDenied = false;

  // Callback for when location permission is newly granted
  Function(geo.Position)? _onLocationPermissionGranted;

  // Getters
  geo.Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get hasLocationPermission => _hasLocationPermission;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;
  bool get isLoadingLocation => _isLoadingLocation;

  // Constructor initializes state
  LocationProvider() {
    _checkLocationPermission();
    // Add this instance as a lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Remove this instance as a lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // App resumed from background, check if location permission status changed
      _checkLocationPermissionOnResume();
    }
  }

  // Set callback for when location permission is newly granted
  void setLocationPermissionGrantedCallback(Function(geo.Position)? callback) {
    _onLocationPermissionGranted = callback;
  }

  // Initialize location services and check permission status
  Future<void> _checkLocationPermission() async {
    _isLoadingLocation = true;
    notifyListeners();

    try {
      // Check if location services are enabled
      _isLocationServiceEnabled =
          await LocationPermissionService.isLocationServiceEnabled();

      // Check if we have permission
      final previousPermissionStatus = _hasLocationPermission;
      _hasLocationPermission =
          await LocationPermissionService.hasLocationPermission();

      // Track if permission was previously denied
      if (!previousPermissionStatus && !_hasLocationPermission) {
        _wasPermissionPreviouslyDenied = true;
      }

      // Set the permission status in MapService
      MapService.setLocationPermissionStatus(_hasLocationPermission);

      // If we have permission and services are enabled, get current location
      if (_hasLocationPermission && _isLocationServiceEnabled) {
        await _updateCurrentLocation();
      }
    } catch (e) {
      debugPrint('Error checking location permission: $e');
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  // Request location permission
  Future<bool> requestLocationPermission(BuildContext context) async {
    _isLoadingLocation = true;
    notifyListeners();

    try {
      final bool result =
          await LocationPermissionService.checkAndRequestLocationPermission(
            context,
          );
      _hasLocationPermission = result;

      // Set the permission status in MapService
      MapService.setLocationPermissionStatus(_hasLocationPermission);

      // If we got permission, update location
      if (_hasLocationPermission) {
        await _updateCurrentLocation();
      }

      return result;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }
// Check location permission when app resumes
  Future<void> _checkLocationPermissionOnResume() async {
    try {
      // Check if location services are enabled
      final wasLocationServiceEnabled = _isLocationServiceEnabled;
      _isLocationServiceEnabled =
          await LocationPermissionService.isLocationServiceEnabled();

      // Check if we have permission
      final previousPermissionStatus = _hasLocationPermission;
      _hasLocationPermission =
          await LocationPermissionService.hasLocationPermission();

      // Set the permission status in MapService
      MapService.setLocationPermissionStatus(_hasLocationPermission);

      // If permission was just granted (and was previously denied)
      if (!previousPermissionStatus &&
          _hasLocationPermission &&
          _wasPermissionPreviouslyDenied) {
        _wasPermissionPreviouslyDenied = false;
        _isLoadingLocation = true;
        notifyListeners();

        // Get current location
        await _updateCurrentLocation();

        // Notify callback that permission was granted with current position
        if (_currentPosition != null && _onLocationPermissionGranted != null) {
          _onLocationPermissionGranted!(_currentPosition!);
        }
      }
      // If location services were just enabled and we have permission
      else if (!wasLocationServiceEnabled &&
          _isLocationServiceEnabled &&
          _hasLocationPermission) {
        _isLoadingLocation = true;
        notifyListeners();

        await _updateCurrentLocation();

        // Notify callback that location is now available
        if (_currentPosition != null && _onLocationPermissionGranted != null) {
          _onLocationPermissionGranted!(_currentPosition!);
        }
      }
      // If we already have permission but don't have current location
      else if (_hasLocationPermission &&
          _isLocationServiceEnabled &&
          _currentPosition == null) {
        await _updateCurrentLocation();
      }

      // Always notify listeners of potential state changes
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking location permission on resume: $e');
    }
  }
  // Update current location and address
  Future<void> _updateCurrentLocation() async {
    if (!_hasLocationPermission || !_isLocationServiceEnabled) {
      return;
    }

    _isLoadingLocation = true;
    notifyListeners();

    try {
      // Get current location
      final position = await geo.Geolocator.getCurrentPosition();
      _currentPosition = position;

      // Get address from geocoding
      final addressData = await PlacesService.getCurrentLocationAddress();
      _currentAddress = addressData['placeName'];
    } catch (e) {
      debugPrint('Error updating current location: $e');
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  // Manually refresh current location
  Future<void> refreshLocation() async {
    if (_isLoadingLocation) {
      return; // Prevent multiple concurrent requests
    }

    await _updateCurrentLocation();
  }

  // Get coordinates as a MapBox Position object
  Position? get currentMapPosition {
    if (_currentPosition == null) {
      return null;
    }

    return Position(_currentPosition!.longitude, _currentPosition!.latitude);
  }
}
