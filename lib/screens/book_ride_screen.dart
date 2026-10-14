import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:intl/intl.dart';
import '../constants/app_routes.dart';
import '../constants/app_theme.dart';
import '../widgets/location_button.dart';
import '../widgets/map_widget.dart';
import '../widgets/location_search_sheet.dart';
import '../widgets/seat_selection_modal.dart';
import '../widgets/schedule_ride_sheet.dart';
import '../widgets/vehicle_selection_sheet.dart';
import '../providers/location_provider.dart';
import '../providers/ride_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/dynamic_fare_provider.dart';
import '../services/map_service.dart';
import '../services/map_markers.dart';
import '../services/geocoding_service.dart';
import '../services/places_service.dart';
import '../services/directions_service.dart';
import '../models/vehicle_type_model.dart';
import 'package:flutter/services.dart';

class BookRideScreen extends StatefulWidget {
  const BookRideScreen({Key? key}) : super(key: key);

  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  MapboxMap? _mapboxMap;
  bool _isMapInitialized = false;
  String? _originMarkerId;
  String? _destinationMarkerId;
  String? _routeId;
  bool _isLoadingRoute = false;
  CircleAnnotationManager? _originCircleManager;
  CircleAnnotationManager? _destinationCircleManager;

  // Tab controller for Shared Cab / Private Cab
  late TabController _tabController;
  String _rideType = 'shared'; // 'shared' or 'private'

  // Seat selection
  int _selectedSeats = 1;

  // Schedule ride
  DateTime? _scheduledDate;

  // Location data
  Position? _originPosition;
  Position? _destinationPosition;
  Position? _currentUserPosition;

  // Add a field for the estimated fare
  int _estimatedFare = 0;
  TextEditingController _fareController = TextEditingController();

  // Add a field for the distance in kilometers
  double _distanceKm = 0.0;

  // Add a field for the selected vehicle
  VehicleType? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen to tab changes
    _tabController.addListener(() {
      setState(() {
        _rideType = _tabController.index == 0 ? 'shared' : 'private';
      });
    });

    // Initialize dynamic fare provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDynamicFareProvider();
    });
  }

  /// Initialize the dynamic fare provider
  Future<void> _initializeDynamicFareProvider() async {
    try {
      final dynamicFareProvider = Provider.of<DynamicFareProvider>(
        context,
        listen: false,
      );
      await dynamicFareProvider.initialize();
    } catch (e) {
      print('Error initializing dynamic fare provider: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get arguments from navigator
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && args.containsKey('currentLocation')) {
      final currentLocation = args['currentLocation'];
      if (currentLocation != null && _fromController.text.isEmpty) {
        setState(() {
          _fromController.text = currentLocation;
        });

        // Try to get the coordinates for this location
        _setLocationFromAddress(currentLocation);
      }
    }

    // Use current location from provider if available
    _getCurrentLocationFromProvider();
  }

  // Helper method to get coordinates from address and set origin position
  Future<void> _setLocationFromAddress(String address) async {
    try {
      // Try to get coordinates from the location provider first
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );

      if (locationProvider.currentPosition != null &&
          locationProvider.currentAddress == address) {
        _originPosition = Position(
          locationProvider.currentPosition!.longitude,
          locationProvider.currentPosition!.latitude,
        );

        // Add marker if map is initialized
        if (_isMapInitialized && _mapboxMap != null) {
          await _updateOriginMarker(_originPosition!);
        }
        return;
      }

      // If not available from provider, try to geocode the address
      // This is a fallback approach - you might want to use a proper geocoding service
      final position = await MapService.getCurrentLocation();
      _originPosition = Position(position.longitude, position.latitude);

      // Add marker if map is initialized
      if (_isMapInitialized && _mapboxMap != null) {
        await _updateOriginMarker(_originPosition!);
      }
    } catch (e) {
      print('Error setting location from address: $e');
      // Fallback to getting current location
      _setCurrentLocationAsFrom();
    }
  }

  Future<void> _getCurrentLocationFromProvider() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    if (locationProvider.currentPosition != null &&
        locationProvider.currentAddress != null) {
      _currentUserPosition = Position(
        locationProvider.currentPosition!.longitude,
        locationProvider.currentPosition!.latitude,
      );

      // If from field is empty, use current location
      if (_fromController.text.isEmpty) {
        setState(() {
          _fromController.text = locationProvider.currentAddress!;
          _originPosition = _currentUserPosition;
        });

        // Add marker if map is initialized
        if (_isMapInitialized && _mapboxMap != null) {
          await _updateOriginMarker(_originPosition!);
        }
      }
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _tabController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    setState(() {
      _isMapInitialized = true;
    });

    // If we already have positions, add markers
    _updateMarkersAfterMapInitialized();

    // If we have origin position but no marker was set yet, ensure it's added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_originPosition != null) {
        _updateOriginMarker(_originPosition!);
      }
    });
  }

  void _updateMarkersAfterMapInitialized() {
    if (_isMapInitialized && _mapboxMap != null) {
      // Add origin marker if we have the position
      if (_originPosition != null) {
        _updateOriginMarker(_originPosition!);
      }

      // Add destination marker if we have the position
      if (_destinationPosition != null) {
        _updateDestinationMarker(_destinationPosition!);
      }

      // Draw route if we have both positions
      if (_originPosition != null && _destinationPosition != null) {
        _drawRoute();
      }
    }
  }

  // Update origin marker by removing old one and adding new one
  Future<void> _updateOriginMarker(Position position) async {
    if (_mapboxMap == null) return;

    try {
      // Remove existing origin marker if exists
      if (_originCircleManager != null && _originMarkerId != null) {
        await _originCircleManager!.deleteAll();
        _originMarkerId = null;
      }

      // Add new origin marker
      await _addOriginMarker(position);

      // Center map on the new marker location
      await _mapboxMap!.flyTo(
        CameraOptions(center: Point(coordinates: position), zoom: 15.0),
        MapAnimationOptions(duration: 1000),
      );
    } catch (e) {
      print('Error updating origin marker: $e');
    }
  }

  Future<void> _setCurrentLocationAsFrom() async {
    try {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );

      // Try to get location from provider first
      if (locationProvider.currentPosition != null &&
          locationProvider.currentAddress != null) {
        setState(() {
          _fromController.text = locationProvider.currentAddress!;
          _originPosition = Position(
            locationProvider.currentPosition!.longitude,
            locationProvider.currentPosition!.latitude,
          );
        });

        // Add marker if map is initialized
        if (_isMapInitialized && _mapboxMap != null) {
          await _updateOriginMarker(_originPosition!);

          // If we have destination, draw route
          if (_destinationPosition != null) {
            await _drawRoute();
          }
        }

        return;
      }

      // If not available in provider, get current location directly
      final position = await MapService.getCurrentLocation();

      // Get address from geocoding service
      final result = await GeocodingService.reverseGeocode(
        position.longitude,
        position.latitude,
      );

      // Update text field and position
      setState(() {
        _fromController.text = result['placeName'];
        _originPosition = Position(position.longitude, position.latitude);
      });

      // Add marker if map is initialized
      if (_isMapInitialized && _mapboxMap != null) {
        await _updateOriginMarker(_originPosition!);

        // If we have destination, draw route
        if (_destinationPosition != null) {
          await _drawRoute();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: ${e.toString()}')),
        );
      }
    }
  }

  // Add origin marker to the map
  Future<void> _addOriginMarker(Position position) async {
    if (_mapboxMap == null) return;

    // Create circle annotation manager if not exists
    _originCircleManager ??=
        await _mapboxMap!.annotations.createCircleAnnotationManager();

    // Create circle annotation options
    final options = CircleAnnotationOptions(
      geometry: Point(coordinates: position),
      circleColor: Colors.green.value,
      circleRadius: 10.0,
      circleStrokeWidth: 2.0,
      circleStrokeColor: Colors.white.value,
    );

    // Add the annotation and store the ID
    final annotation = await _originCircleManager!.create(options);
    _originMarkerId = annotation.id;
  }

  // Add destination marker to the map
  Future<void> _addDestinationMarker(Position position) async {
    if (_mapboxMap == null) return;

    // Create circle annotation manager if not exists
    _destinationCircleManager ??=
        await _mapboxMap!.annotations.createCircleAnnotationManager();

    // Create circle annotation options
    final options = CircleAnnotationOptions(
      geometry: Point(coordinates: position),
      circleColor: Colors.red.value,
      circleRadius: 10.0,
      circleStrokeWidth: 2.0,
      circleStrokeColor: Colors.white.value,
    );

    // Add the annotation and store the ID
    final annotation = await _destinationCircleManager!.create(options);
    _destinationMarkerId = annotation.id;
  }

  // Update destination marker by removing old one and adding new one
  Future<void> _updateDestinationMarker(Position position) async {
    if (_mapboxMap == null) return;

    try {
      // Remove existing destination marker if exists
      if (_destinationCircleManager != null && _destinationMarkerId != null) {
        await _destinationCircleManager!.deleteAll();
        _destinationMarkerId = null;
      }

      // Add new destination marker
      await _addDestinationMarker(position);
    } catch (e) {
      print('Error updating destination marker: $e');
    }
  }

  // Add method to calculate estimated fare based on route distance
  void _calculateEstimatedFare(double distanceInKm) {
    // Update distance
    _distanceKm = distanceInKm;

    // Basic fare calculation
    const baseRate = 8.0; // Base rate per km
    const baseFare = 25.0; // Base fare
    final estimatedFare = baseFare + (baseRate * distanceInKm);

    setState(() {
      _estimatedFare = estimatedFare.toInt();
      _fareController.text = '₹${estimatedFare.toInt()}';
    });
  }

  // Handle vehicle selection
  void _handleVehicleSelection(
    VehicleType selectedVehicle, [
    int? modifiedFare,
  ]) {
    setState(() {
      _selectedVehicle = selectedVehicle;
      // Update estimated fare based on selected vehicle or use modified fare
      if (modifiedFare != null) {
        _estimatedFare = modifiedFare;
      } else {
        _estimatedFare = selectedVehicle.calculateFare(_distanceKm);
      }
      _fareController.text = '₹${_estimatedFare.toInt()}';
    });

    // Automatically create ride request with selected vehicle
    _createRideRequestWithVehicle(selectedVehicle, modifiedFare);
  }

  // Create ride request with selected vehicle
  void _createRideRequestWithVehicle(
    VehicleType selectedVehicle, [
    int? modifiedFare,
  ]) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final rideProvider = Provider.of<RideProvider>(context, listen: false);

    // Check if user is authenticated
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book a ride')),
      );
      return;
    }

    if (_originPosition == null || _destinationPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set both pickup and destination locations'),
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Handle "any" option - extract available vehicle types
      String vehicleTypeToSend = selectedVehicle.id;
      List<String>? availableVehicleTypes;

      if (selectedVehicle.id == 'any') {
        // Extract available types from description field
        String availableTypesString = selectedVehicle.description;
        if (availableTypesString.contains(',')) {
          availableVehicleTypes = availableTypesString.split(',');
        }
      }

      // Use modified fare if provided, otherwise calculate from vehicle
      final fareToUse =
          modifiedFare ?? selectedVehicle.calculateFare(_distanceKm);

      final rideRequest = await rideProvider.createRideRequest(
        riderId: authProvider.currentUser!.id,
        fromAddress: _fromController.text,
        toAddress: _toController.text,
        fromLat: _originPosition!.lat,
        fromLng: _originPosition!.lng,
        toLat: _destinationPosition!.lat,
        toLng: _destinationPosition!.lng,
        initialFare: fareToUse, // Use the modified fare or calculated fare
        scheduledTime: _rideType == 'private' ? _scheduledDate : null,
        seats: _rideType == 'shared' ? _selectedSeats : 1,
        rideType: _rideType,
        vehicleType: vehicleTypeToSend,
        availableVehicleTypes: availableVehicleTypes,
        distanceKm: _distanceKm,
        userName: authProvider.currentUser!.name,
        userPhone: authProvider.currentUser!.phoneNumber,
      );

      // Hide loading indicator
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Navigate to user to driver matching screen
      if (context.mounted) {
        Navigator.pushNamed(context, AppRoutes.userToDriverMatching);
      }
    } catch (e) {
      // Hide loading indicator
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating ride request: ${e.toString()}'),
          ),
        );
      }
    }
  }

  // Update the _drawRoute method to calculate fare
  Future<void> _drawRoute() async {
    if (_mapboxMap == null ||
        _originPosition == null ||
        _destinationPosition == null) {
      return;
    }

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      // Get directions from the API
      final response = await DirectionsService.getDirections(
        _originPosition!.lng,
        _originPosition!.lat,
        _destinationPosition!.lng,
        _destinationPosition!.lat,
      );

      if (response != null && response.containsKey('geometry')) {
        final List<dynamic> coordinates =
            response['geometry']['coordinates'] as List<dynamic>;
        final List<Position> routeCoordinates =
            coordinates
                .map(
                  (coord) => Position(coord[0] as double, coord[1] as double),
                )
                .toList();

        // Clear any existing route
        if (_routeId != null && _mapboxMap != null) {
          await MapMarkers.removeRoute(_mapboxMap!, _routeId!);
          _routeId = null;
        }

        // Draw the new route
        _routeId = await MapMarkers.addRoute(_mapboxMap!, routeCoordinates);

        // Update camera to show the entire route
        await _mapboxMap!.flyTo(
          CameraOptions(
            center: Point(
              coordinates: Position(
                (_originPosition!.lng + _destinationPosition!.lng) / 2,
                (_originPosition!.lat + _destinationPosition!.lat) / 2,
              ),
            ),
            zoom: 12.0,
            padding: MbxEdgeInsets(
              top: 100,
              left: 100,
              bottom: 300,
              right: 100,
            ),
          ),
          MapAnimationOptions(duration: 500, startDelay: 0),
        );

        // Calculate and update estimated fare based on distance
        final double distanceInMeters = response['distance'] as double;
        final double distanceInKm = distanceInMeters / 1000;
        _calculateEstimatedFare(distanceInKm);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error drawing route: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  void _handleLocationButtonPress() async {
    if (_mapboxMap == null) return;

    if (_originPosition != null && _destinationPosition != null) {
      // If both origin and destination are set, first zoom to see both locations
      await MapMarkers.fitMapToShowRoute(
        mapboxMap: _mapboxMap!,
        origin: _originPosition!,
        destination: _destinationPosition!,
      );
    } else if (_currentUserPosition != null) {
      // Zoom to current user position
      await _mapboxMap!.setCamera(
        CameraOptions(
          center: Point(coordinates: _currentUserPosition!),
          zoom: 15.0,
        ),
      );

      if (_fromController.text.isEmpty) {
        // Set current location as origin if from field is empty
        _setCurrentLocationAsFrom();
      }
    } else {
      // Try to get current location
      _setCurrentLocationAsFrom();
    }
  }

  // Show the search location sheet
  void _showFromLocationSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => LocationSearchSheet(
            title: 'Choose start location',
            initialLocation:
                _fromController.text.isNotEmpty ? _fromController.text : null,
            currentUserPosition: _currentUserPosition,
            onLocationSelected: (location) {
              setState(() {
                _fromController.text = location['placeName'] ?? '';
                _originPosition = location['coordinates'];
              });

              // Add marker and draw route if needed
              if (_isMapInitialized && _mapboxMap != null) {
                _updateOriginMarker(_originPosition!);
                if (_destinationPosition != null) {
                  _drawRoute();
                }
              }
            },
          ),
    );
  }

  // Show the search location sheet for destination
  void _showToLocationSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => LocationSearchSheet(
            title: 'Choose destination',
            initialLocation:
                _toController.text.isNotEmpty ? _toController.text : null,
            currentUserPosition: _currentUserPosition,
            onLocationSelected: (location) {
              setState(() {
                _toController.text = location['placeName'] ?? '';
                _destinationPosition = location['coordinates'];
              });

              // Add marker and draw route if needed
              if (_isMapInitialized && _mapboxMap != null) {
                _updateDestinationMarker(_destinationPosition!);
                if (_originPosition != null) {
                  _drawRoute();
                }
              }
            },
          ),
    );
  }

  // Show seat selection modal
  void _showSeatSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SeatSelectionModal(
            initialSeats: _selectedSeats,
            onSeatSelected: (seats) {
              setState(() {
                _selectedSeats = seats;
              });
            },
          ),
    );
  }

  // Show schedule ride sheet
  void _showScheduleRideSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ScheduleRideSheet(
            initialDate: _scheduledDate,
            onDateSelected: (date) {
              setState(() {
                _scheduledDate = date;
              });
            },
          ),
    );
  }

  // Format the scheduled date for display
  String _formatScheduledDate() {
    if (_scheduledDate == null) {
      return 'now';
    }

    return DateFormat('dd MMM, h:mm a').format(_scheduledDate!);
  }

  // Create a new ride request with fare negotiation
  void _createRideRequest() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final rideProvider = Provider.of<RideProvider>(context, listen: false);

    // Check if user is authenticated
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book a ride')),
      );
      return;
    }

    if (_originPosition == null || _destinationPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set both pickup and destination locations'),
        ),
      );
      return;
    }

    if (_fareController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your proposed fare')),
      );
      return;
    }

    // Parse fare amount
    final String fareText =
        _fareController.text.replaceAll('₹', '').replaceAll(',', '').trim();
    final int initialFare = int.tryParse(fareText) ?? _estimatedFare;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Create ride request through provider with all required parameters
      final rideRequest = await rideProvider.createRideRequest(
        riderId: authProvider.currentUser!.id,
        fromAddress: _fromController.text,
        toAddress: _toController.text,
        fromLat: _originPosition!.lat,
        fromLng: _originPosition!.lng,
        toLat: _destinationPosition!.lat,
        toLng: _destinationPosition!.lng,
        initialFare: initialFare,
        scheduledTime: _rideType == 'private' ? _scheduledDate : null,
        seats: _rideType == 'shared' ? _selectedSeats : 1,
        rideType: _rideType,
        vehicleType: _selectedVehicle?.id ?? 'car',
        availableVehicleTypes:
            _selectedVehicle?.id == 'any'
                ? _selectedVehicle?.description.split(',')
                : null,
        distanceKm: _distanceKm,
        userName: authProvider.currentUser!.name,
        userPhone: authProvider.currentUser!.phoneNumber,
      );

      // Hide loading indicator
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Navigate to user to driver matching screen
      if (context.mounted) {
        Navigator.pushNamed(context, AppRoutes.userToDriverMatching);
      }
    } catch (e) {
      // Hide loading indicator
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating ride request: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map background
          RydeMapWidget(
            showUserLocation: true,
            onMapCreated: _onMapCreated,
            onMapClick: null, // We want full map interactivity
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // App bar with back button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Book Ride',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Empty space to center title
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom sheet with ride options
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tabs for Find Pool / Offer Pool
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Shared Ride'),
                            Tab(text: 'Private Ride'),
                          ],
                          indicatorColor:
                              _tabController.index == 0
                                  ? Colors.green
                                  : Colors.deepPurpleAccent,
                          labelColor:
                              _tabController.index == 0
                                  ? Colors.green
                                  : Colors.deepPurpleAccent,
                          unselectedLabelColor: Colors.grey,
                          indicatorWeight: 3,
                        ),
                      ),

                      // Main content
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // From field
                            GestureDetector(
                              onTap: _showFromLocationSearchSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      color: Colors.green,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        _fromController.text.isNotEmpty
                                            ? _fromController.text
                                            : 'Choose start location',
                                        style: TextStyle(
                                          color:
                                              _fromController.text.isNotEmpty
                                                  ? Colors.black
                                                  : Colors.grey,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // To field
                            GestureDetector(
                              onTap: _showToLocationSearchSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _toController.text.isNotEmpty
                                            ? _toController.text
                                            : 'Choose destination',
                                        style: TextStyle(
                                          color:
                                              _toController.text.isNotEmpty
                                                  ? Colors.black
                                                  : Colors.grey,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Schedule time and seats row
                            Row(
                              children: [
                                // Schedule time button - only show for private ride
                                if (_rideType == 'private')
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _showScheduleRideSheet,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _formatScheduledDate(),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                // Add spacing only if both are shown
                                if (_rideType == 'private' &&
                                    _rideType == 'shared')
                                  const SizedBox(width: 12),

                                // Number of seats button - only show for shared cab
                                if (_rideType == 'shared')
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _showSeatSelectionModal,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.airline_seat_recline_normal,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '$_selectedSeats Seat${_selectedSeats > 1 ? 's' : ''}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Find Ride button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoadingRoute
                                        ? null
                                        : () {
                                          if (_fromController.text.isNotEmpty &&
                                              _toController.text.isNotEmpty) {
                                            if (_estimatedFare > 0) {
                                              // Show vehicle selection sheet
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor:
                                                    Colors.transparent,
                                                builder:
                                                    (
                                                      context,
                                                    ) => VehicleSelectionSheet(
                                                      distanceKm: _distanceKm,
                                                      rideType: _rideType,
                                                      onVehicleSelected:
                                                          _handleVehicleSelection,
                                                    ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Please calculate route first',
                                                  ),
                                                ),
                                              );
                                            }
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please enter both locations',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                                child:
                                    _isLoadingRoute
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text(
                                          'FIND RIDE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Location button
          if (_isMapInitialized)
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).size.height * 0.37,
              child: LocationButton(
                mapboxMap: _mapboxMap,
                onLocationButtonPressed: _handleLocationButtonPress,
              ),
            ),
        ],
      ),
    );
  }
}
