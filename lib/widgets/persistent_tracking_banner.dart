import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_routes.dart';
import '../constants/app_theme.dart';
import '../services/active_ride_service.dart';
import '../providers/ride_provider.dart';
import '../models/ride_request_model.dart';
import 'dart:async';

class PersistentTrackingBanner extends StatefulWidget {
  final Widget child;
  final String? currentRouteName;

  const PersistentTrackingBanner({
    super.key,
    required this.child,
    this.currentRouteName,
  });

  @override
  State<PersistentTrackingBanner> createState() =>
      _PersistentTrackingBannerState();
}

class _PersistentTrackingBannerState extends State<PersistentTrackingBanner>
    with TickerProviderStateMixin {
  String? _activeRideId;
  RideRequest? _activeRide;
  bool _isVisible = false;
  StreamSubscription<String?>? _activeRideSubscription;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startListening();
    _checkInitialState();
  }

  @override
  void dispose() {
    _activeRideSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _startListening() {
    _activeRideSubscription = ActiveRideService.activeRideStream.listen(
      (activeRideId) async {
        if (!mounted) return;

        if (activeRideId != null && activeRideId != _activeRideId) {
          // New active ride
          _activeRideId = activeRideId;
          await _loadActiveRideDetails();
          _checkVisibility();
        } else if (activeRideId == null && _activeRideId != null) {
          // Active ride cleared
          _activeRideId = null;
          _activeRide = null;
          _hideBanner();
        }
      },
      onError: (error) {
        print('❌ Error listening to active ride stream: $error');
      },
    );
  }

  Future<void> _checkInitialState() async {
    try {
      final activeRideId = await ActiveRideService.getCurrentActiveRideId();
      if (activeRideId != null && mounted) {
        _activeRideId = activeRideId;
        await _loadActiveRideDetails();
        _checkVisibility();
      }
    } catch (e) {
      print('❌ Error checking initial active ride state: $e');
    }
  }

  Future<void> _loadActiveRideDetails() async {
    try {
      final rideDetails = await ActiveRideService.getActiveRideDetails();
      if (mounted && rideDetails != null) {
        setState(() {
          _activeRide = rideDetails;
        });
      }
    } catch (e) {
      print('❌ Error loading active ride details: $e');
    }
  }

  void _checkVisibility() {
    if (!mounted) return;

    final shouldShow = _shouldShowBanner();

    if (shouldShow && !_isVisible) {
      _showBanner();
    } else if (!shouldShow && _isVisible) {
      _hideBanner();
    }
  }

  bool _shouldShowBanner() {
    // Don't show if no active ride
    if (_activeRideId == null || _activeRide == null) return false;

    // Don't show if ride is not in active status
    final status = _activeRide!.status;
    if (status != 'confirmed' && status != 'started') return false;

    // Don't show if currently on tracking screen
    if (widget.currentRouteName == AppRoutes.tracking) return false;

    return true;
  }

  void _showBanner() {
    if (!mounted || _isVisible) return;

    setState(() {
      _isVisible = true;
    });

    _animationController.forward();
  }

  void _hideBanner() {
    if (!mounted || !_isVisible) return;

    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  void _navigateToTracking() {
    if (_activeRideId != null) {
      // Update ride provider with current active ride
      final rideProvider = Provider.of<RideProvider>(context, listen: false);
      if (_activeRide != null) {
        rideProvider.setCurrentRideRequest(_activeRide!);
      }

      Navigator.pushNamed(context, AppRoutes.tracking);
    }
  }

  String _getBannerText() {
    if (_activeRide == null) return 'You have an active ride';

    final status = _activeRide!.status;
    final ridePhase = _activeRide!.ridePhase;

    if (status == 'confirmed') {
      return 'Waiting for driver to start the ride';
    } else if (status == 'started') {
      if (ridePhase == 'going_to_pickup') {
        return 'Driver is coming to pick you up';
      } else if (ridePhase == 'going_to_destination') {
        return 'On the way to destination';
      } else {
        return 'Your ride is in progress';
      }
    } else {
      return 'You have an active ride';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isVisible)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value * 80),
                    child: Opacity(opacity: _fadeAnimation.value, child: child),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _navigateToTracking,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            // Animated car icon
                            TweenAnimationBuilder<double>(
                              duration: const Duration(seconds: 2),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset((value * 10) - 5, 0),
                                  child: Icon(
                                    Icons.directions_car,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),

                            // Text content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _getBannerText(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap to return to tracking',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Arrow icon
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white.withOpacity(0.8),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Extension to easily wrap any widget with the tracking banner
extension TrackingBannerExtension on Widget {
  Widget withTrackingBanner({String? currentRouteName}) {
    return PersistentTrackingBanner(
      currentRouteName: currentRouteName,
      child: this,
    );
  }
}
