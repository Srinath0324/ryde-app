import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle_type_model.dart';
import '../constants/app_theme.dart';
import '../providers/dynamic_fare_provider.dart';
import 'change_offer_card.dart';
import 'ride_request_inner_content.dart';

class VehicleSelectionSheet extends StatefulWidget {
  final double distanceKm;
  final String rideType;
  final Function(VehicleType, int?)
  onVehicleSelected; // Added optional double for modified fare

  const VehicleSelectionSheet({
    super.key,
    required this.distanceKm,
    required this.rideType,
    required this.onVehicleSelected,
  });

  @override
  State<VehicleSelectionSheet> createState() => _VehicleSelectionSheetState();
}

class _VehicleSelectionSheetState extends State<VehicleSelectionSheet> {
  VehicleType? _selectedVehicle;
  List<VehicleType> _availableVehicles = [];
  Map<String, int> _dynamicFares = {}; // Store dynamic fares for each vehicle
  int? _currentModifiedFare; // Track current fare from change offer card
  bool _isBooking = false; // Add loading state for booking
  bool _isLoadingFares = false; // Loading state for fare calculation

  @override
  void initState() {
    super.initState();
    _loadAvailableVehicles();
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateDynamicFares();
    });
  }

  void _loadAvailableVehicles() {
    List<VehicleType> allVehicles = VehicleTypes.getDefaultVehicles();

    // Filter vehicles based on ride type and distance
    _availableVehicles =
        allVehicles.where((vehicle) {
          // Rule 1: If shared ride, don't show bike option
          if (widget.rideType == 'shared' && vehicle.id == 'bike') {
            return false;
          }

          // Rule 2: If distance > 10km, don't show e-rickshaw
          if (widget.distanceKm > 10.0 && vehicle.id == 'e_rickshaw') {
            return false;
          }

          return true;
        }).toList();

    // Set default selection to first vehicle (Book Any)
    if (_availableVehicles.isNotEmpty) {
      _selectedVehicle = _availableVehicles.first;
    }
    setState(() {});
  }

  /// Calculate dynamic fares for all available vehicles
  Future<void> _calculateDynamicFares() async {
    setState(() {
      _isLoadingFares = true;
    });

    try {
      final dynamicFareProvider = Provider.of<DynamicFareProvider>(
        context,
        listen: false,
      );

      // Check if city is supported
      if (!dynamicFareProvider.isCitySupported) {
        // Show coming soon dialog and fallback to static calculation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          dynamicFareProvider.showComingSoonDialog(context);
        });
        _useFallbackFares();
        return;
      }

      // Calculate dynamic fares for available vehicles
      final vehicleIds =
          _availableVehicles
              .where((vehicle) => vehicle.id != 'any')
              .map((vehicle) => vehicle.id)
              .toList();

      final fares = await dynamicFareProvider.calculateFareForAllVehicles(
        distanceKm: widget.distanceKm,
        rideType: widget.rideType,
        vehicleTypes: vehicleIds,
      );

      setState(() {
        _dynamicFares = fares;
        // Set 'any' fare as average of all vehicle fares
        if (fares.isNotEmpty) {
          final averageFare =
              fares.values.reduce((a, b) => a + b) ~/ fares.length;
          _dynamicFares['any'] = averageFare;
        }
      });
    } catch (e) {
      print('Error calculating dynamic fares: $e');
      // Fallback to static fare calculation
      _useFallbackFares();
    } finally {
      setState(() {
        _isLoadingFares = false;
      });
    }
  }

  /// Use fallback static fares when dynamic calculation fails
  void _useFallbackFares() {
    setState(() {
      _dynamicFares.clear();
      for (var vehicle in _availableVehicles) {
        _dynamicFares[vehicle.id] =
            vehicle.calculateFare(widget.distanceKm).round();
      }
    });
  }

  // Get available vehicle types excluding "any" option
  List<String> _getAvailableVehicleTypes() {
    return _availableVehicles
        .where((vehicle) => vehicle.id != 'any')
        .map((vehicle) => vehicle.id)
        .toList();
  }

  void _selectVehicle(VehicleType vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
      _currentModifiedFare =
          null; // Reset modified fare when selecting a new vehicle
    });
  }

  void _onFareChanged(int newFare) {
    _currentModifiedFare = newFare;
  }

  void _bookSelectedVehicle() async {
    if (_selectedVehicle != null && !_isBooking) {
      setState(() {
        _isBooking = true; // Set loading state to true
      });

      try {
        final originalFare = _selectedVehicle!.calculateFare(widget.distanceKm);
        final modifiedFare =
            _currentModifiedFare != null && _currentModifiedFare != originalFare
                ? _currentModifiedFare
                : null;

        // If "any" is selected, create a special vehicle type with available types
        if (_selectedVehicle!.id == 'any') {
          final availableTypes = _getAvailableVehicleTypes();
          final anyVehicleWithTypes = _selectedVehicle!.copyWith(
            // We'll store available types in the description field temporarily
            description: availableTypes.join(','),
          );
          widget.onVehicleSelected(anyVehicleWithTypes, modifiedFare);
        } else {
          widget.onVehicleSelected(_selectedVehicle!, modifiedFare);
        }

        // Close the sheet after a brief delay to show loading state
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        // Handle any errors and reset loading state
        if (mounted) {
          setState(() {
            _isBooking = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error booking ride: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Vehicle',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.rideType == 'shared' ? 'Shared' : 'Private'} ride • ${widget.distanceKm.toStringAsFixed(1)} km',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Vehicle list (scrollable)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _availableVehicles.length,
              itemBuilder: (context, index) {
                final vehicle = _availableVehicles[index];
                // Use dynamic fare if available, otherwise fallback to static calculation
                final estimatedFare =
                    _dynamicFares[vehicle.id]?.toInt() ??
                    vehicle.calculateFare(widget.distanceKm);
                final isSelected = _selectedVehicle?.id == vehicle.id;

                return GestureDetector(
                  onTap: () => _selectVehicle(vehicle),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppTheme.primaryColor.withOpacity(0.1)
                              : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey[200]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Vehicle icon
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _buildVehicleIcon(vehicle),
                        ),

                        const SizedBox(width: 16),

                        // Vehicle details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                vehicle.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${vehicle.maxPassengers}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Fare
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _isLoadingFares
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryColor,
                                    ),
                                  ),
                                )
                                : Text(
                                  '₹${estimatedFare.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            if (isSelected && !_isLoadingFares)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                child: Icon(
                                  Icons.check_circle,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Change Offer Card (fixed, non-scrollable)
          if (_selectedVehicle != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),

              child: ChangeOfferCard(
                recommendedFare:
                    _dynamicFares[_selectedVehicle!.id]?.toInt() ??
                    _selectedVehicle!.calculateFare(widget.distanceKm),
                showBackButton: true,
                showSendOfferButton: false,
                onFareChanged: _onFareChanged,
              ),
            ),

          // Book button (fixed, non-scrollable)
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    (_selectedVehicle != null && !_isBooking)
                        ? _bookSelectedVehicle
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child:
                    _isBooking
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          _selectedVehicle != null
                              ? 'Book ${_selectedVehicle!.name}'
                              : 'Select Vehicle',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleIcon(VehicleType vehicle) {
    // Using existing icons from assets with fallback
    String iconPath = vehicle.iconPath;

    // Map to existing icons or use fallback
    Widget icon;

    switch (vehicle.id) {
      case 'any':
        icon = Image.asset(
          'assets/icons/search.png',
          width: 24,
          height: 24,
          errorBuilder:
              (context, error, stackTrace) =>
                  const Icon(Icons.search, size: 24, color: Colors.grey),
        );
        break;
      case 'car':
        // Use directions icon as car placeholder
        icon = const Icon(Icons.directions_car, size: 24, color: Colors.blue);
        break;
      case 'auto':
        // Use local shipping icon as auto placeholder
        icon = const Icon(Icons.local_shipping, size: 24, color: Colors.orange);
        break;
      case 'bike':
        // Use motorcycle icon
        icon = const Icon(Icons.two_wheeler, size: 24, color: Colors.red);
        break;
      case 'e_rickshaw':
        // Use electric car icon
        icon = const Icon(
          Icons.electric_rickshaw,
          size: 24,
          color: Colors.green,
        );
        break;
      default:
        icon = const Icon(Icons.directions_car, size: 24, color: Colors.grey);
    }

    return Center(child: icon);
  }
}
