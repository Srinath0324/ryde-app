import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../services/places_service.dart';
import '../constants/app_theme.dart';

class LocationSearchSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onLocationSelected;
  final String? initialLocation;
  final Position? currentUserPosition;
  final String title;

  const LocationSearchSheet({
    Key? key,
    required this.onLocationSelected,
    this.initialLocation,
    this.currentUserPosition,
    required this.title,
  }) : super(key: key);

  @override
  State<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<LocationSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _recentLocations = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _searchController.text = widget.initialLocation!;
    }

    // Set focus automatically when sheet opens
    Future.delayed(const Duration(milliseconds: 300), () {
      _searchFocusNode.requestFocus();
    });

    _searchController.addListener(_onSearchChanged);

    // Load some mock recent locations (in a real app, this would come from storage)
    _loadRecentLocations();
  }

  void _loadRecentLocations() {
    // This would normally load from a database or shared preferences
    _recentLocations = [
      {'text': 'Home', 'placeName': '13.065167,77.526867'},
      {'text': 'Work', 'placeName': 'Office Location'},
      // Add more saved locations as needed
    ];
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Debounce the search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _getLocationSuggestions(_searchController.text);
      }
    });
  }

  Future<void> _getLocationSuggestions(String query) async {
    try {
      final suggestions = await PlacesService.getSuggestions(
        query,
        proximityLatitude:
            widget.currentUserPosition?.lat != null
                ? widget.currentUserPosition!.lat.toDouble()
                : null,
        proximityLongitude:
            widget.currentUserPosition?.lng != null
                ? widget.currentUserPosition!.lng.toDouble()
                : null,
      );

      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error getting suggestions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleChooseOnMap() {
    Navigator.pop(context);
    // The calling widget should handle this separately
  }

  void _handleCurrentLocation() async {
    try {
      final currentLocation = await PlacesService.getCurrentLocationAddress();
      widget.onLocationSelected(currentLocation);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get current location: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () {
                    // Voice search feature would go here
                  },
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search for a place',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Choose on map button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: _handleChooseOnMap,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.map, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Text('Choose on map'),
                ],
              ),
            ),
          ),

          // Current location button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GestureDetector(
              onTap: _handleCurrentLocation,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.my_location, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Text('Current location'),
                ],
              ),
            ),
          ),

          const Divider(height: 32),

          // Suggestions or recent places
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _suggestions.isNotEmpty
                    ? ListView.builder(
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text(suggestion['text'] ?? ''),
                          subtitle: Text(
                            suggestion['placeName'] ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            widget.onLocationSelected(suggestion);
                            Navigator.pop(context);
                          },
                        );
                      },
                    )
                    : _searchController.text.isEmpty
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
                          child: Text(
                            'Recent places',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _recentLocations.length,
                            itemBuilder: (context, index) {
                              final location = _recentLocations[index];
                              return ListTile(
                                leading: const Icon(Icons.location_on),
                                title: Text(location['text'] ?? ''),
                                subtitle: Text(
                                  location['placeName'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  widget.onLocationSelected(location);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    )
                    : const Center(child: Text('No results found')),
          ),
        ],
      ),
    );
  }
}
