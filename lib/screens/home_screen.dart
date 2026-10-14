import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../constants/app_routes.dart';
import '../constants/app_theme.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ride_history_provider.dart';
import '../models/ride_history_model.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/location_button.dart';
import '../widgets/map_widget.dart';
import '../services/map_service.dart';
import '../services/geocoding_service.dart';
import 'package:geolocator/geolocator.dart' as geo;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  MapboxMap? _mapboxMap;
  bool _isMapInitialized = false;
  String? _currentLocationAddress;
  bool _isLoadingLocation = false;

  LocationProvider? _locationProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLatestRide();
      _initializeLocationHandling();
      _updateCurrentLocationAddress();
    });
  }

  @override
  void dispose() {
    // Clean up location callback
    _locationProvider?.setLocationPermissionGrantedCallback(null);
    super.dispose();
  }

  // Initialize location handling with callback
  void _initializeLocationHandling() {
    _locationProvider = Provider.of<LocationProvider>(context, listen: false);

    // Set up callback for when location permission is granted externally
    _locationProvider?.setLocationPermissionGrantedCallback((
      geo.Position position,
    ) {
      // Zoom to current location when permission is granted
      if (_mapboxMap != null && _isMapInitialized) {
        _zoomToCurrentLocation();
      }
    });
  }

  // Zoom to current location
  Future<void> _zoomToCurrentLocation() async {
    if (_mapboxMap == null) return;

    try {
      await MapService.animateCameraToCurrentLocation(_mapboxMap!);
      // Also update the current location address
      _updateCurrentLocationAddress();
    } catch (e) {
      debugPrint('Error zooming to current location: $e');
    }
  }

  // Format the date for display
  String _formatDate(DateTime dateTime) {
    return DateFormat('dd MMMM yyyy, hh:mm a').format(dateTime);
  }

  // Load latest ride from provider
  Future<void> _loadLatestRide() async {
    final rideHistoryProvider = Provider.of<RideHistoryProvider>(
      context,
      listen: false,
    );
    await rideHistoryProvider.loadLatestRide();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    setState(() {
      _isMapInitialized = true;
    });

    // Get current location when map is created
    _updateCurrentLocationAddress();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      if (locationProvider.hasLocationPermission &&
          locationProvider.currentPosition != null) {
        _zoomToCurrentLocation();
      }
    });
  }

  Future<void> _updateCurrentLocationAddress() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Get current location
      final position = await MapService.getCurrentLocation();

      // Get address from geocoding service
      final result = await GeocodingService.reverseGeocode(
        position.longitude,
        position.latitude,
      );

      setState(() {
        _currentLocationAddress = result['placeName'];
        _isLoadingLocation = false;
      });
    } catch (e) {
      print('Error getting current location address: $e');
      setState(() {
        _currentLocationAddress = 'Location unavailable';
        _isLoadingLocation = false;
      });
    }
  }

  void _handleLocationButtonPress() {
    setState(() {
      _isLoadingLocation = true;
    });

    // The LocationButton widget will handle permissions
    // We just need to set up the callback for when location is obtained
  }

  void _onLocationPermissionResult(bool success) {
    if (success) {
      // Permission granted and location obtained, update address
      _updateCurrentLocationAddress();
    } else {
      // Permission denied or error getting location
      setState(() {
        _isLoadingLocation = false;
        _currentLocationAddress = 'Location access required';
      });
    }
  }

  // Build the recent rides section
  Widget _buildRecentRidesSection(BuildContext context) {
    return Consumer<RideHistoryProvider>(
      builder: (context, rideHistoryProvider, child) {
        final latestRide = rideHistoryProvider.latestRide;
        final isLoading = rideHistoryProvider.isLoading;
        final hasError = rideHistoryProvider.errorMessage != null;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Rides',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (hasError)
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(
                        '${rideHistoryProvider.errorMessage}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                )
              else if (latestRide == null)
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/no-result.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No ride history found',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                // Recent ride card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Map thumbnail and route details
                      Row(
                        children: [
                          // Small map thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/Map.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // From and To locations
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        latestRide.fromAddress,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        latestRide.toAddress,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // Ride details (date, driver, seats, status)
                      Row(
                        children: [
                          // Date & Time
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Date & Time',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatDate(latestRide.dateTime),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Driver
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                const Text(
                                  'Driver',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  latestRide.driverName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // // Ride Type
                          // Column(
                          //   crossAxisAlignment: CrossAxisAlignment.start,
                          //   children: [
                          //     const Text(
                          //       'Ride Type',
                          //       style: TextStyle(
                          //         fontSize: 12,
                          //         color: Colors.grey,
                          //       ),
                          //     ),
                          //     const SizedBox(height: 4),
                          //     Text(
                          //       latestRide.rideType == 'shared'
                          //           ? 'Shared (${latestRide.seats})'
                          //           : 'Private',
                          //       style: const TextStyle(
                          //         fontSize: 12,
                          //         fontWeight: FontWeight.w500,
                          //       ),
                          //     ),
                          //   ],
                          // ),

                          // const SizedBox(width: 8),

                          // Fare and Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '₹${latestRide.fare.toInt()} ${latestRide.status}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.user?.name?.split(' ')[0] ?? 'John';

    return Scaffold(
      body: Stack(
        children: [
          // Map background
          RydeMapWidget(showUserLocation: true, onMapCreated: _onMapCreated),

          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome text with sign out button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Welcome $userName',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.logout, size: 22),
                          onPressed: () async {
                            await authProvider.signOut();
                            if (!context.mounted) return;
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.login,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Search bar
                GestureDetector(
                  onTap: () {
                    final isValidLocation =
                        _currentLocationAddress != null &&
                        _currentLocationAddress != 'Location unavailable' &&
                        _currentLocationAddress != 'Location access required';

                    Navigator.pushNamed(
                      context,
                      AppRoutes.bookRide,
                      arguments:
                          isValidLocation
                              ? {'currentLocation': _currentLocationAddress}
                              : null,
                    );
                  },

                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey[400]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isLoadingLocation
                                ? 'Getting your location...'
                                : _currentLocationAddress ??
                                    'Where do you want to go?',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Recent rides section
                _buildRecentRidesSection(context),
              ],
            ),
          ),

          // Location button
          if (_isMapInitialized)
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).size.height * 0.35 + 16,
              child: LocationButton(
                mapboxMap: _mapboxMap,
                onLocationButtonPressed: _handleLocationButtonPress,
                onLocationPermissionResult: _onLocationPermissionResult,
              ),
            ),
        ],
      ),
    );
  }
}
