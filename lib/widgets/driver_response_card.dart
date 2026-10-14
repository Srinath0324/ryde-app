import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/driver_response_model.dart';
import '../constants/app_theme.dart';
import '../services/driver_response_service.dart';

/// Animated wrapper for driver response cards with Gmail-style slide animation
class AnimatedDriverCard extends StatefulWidget {
  final DriverResponse response;
  final bool showBestOfferBadge;
  final bool showTopRatedBadge;
  final VoidCallback onAccept;
  final VoidCallback onNegotiate;
  final bool shouldSlideOut;
  final VoidCallback? onSlideOutComplete;

  const AnimatedDriverCard({
    super.key,
    required this.response,
    required this.showBestOfferBadge,
    required this.showTopRatedBadge,
    required this.onAccept,
    required this.onNegotiate,
    this.shouldSlideOut = false,
    this.onSlideOutComplete,
  });

  @override
  State<AnimatedDriverCard> createState() => _AnimatedDriverCardState();
}

class _AnimatedDriverCardState extends State<AnimatedDriverCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.2, 0), // Slide to the right
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // Listen for animation completion
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onSlideOutComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedDriverCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start slide-out animation when shouldSlideOut becomes true
    if (widget.shouldSlideOut && !oldWidget.shouldSlideOut) {
      _startSlideOutAnimation();
    }
  }

  void _startSlideOutAnimation() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Stack(
            children: [
              // Red background with delete icon (visible during slide)
              if (widget.shouldSlideOut)
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Driver Cancelled',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Actual driver card
              DriverResponseCard(
                response: widget.response,
                showBestOfferBadge: widget.showBestOfferBadge,
                showTopRatedBadge: widget.showTopRatedBadge,
                onAccept: widget.onAccept,
                onNegotiate: widget.onNegotiate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DriverResponseCard extends StatefulWidget {
  final DriverResponse response;
  final VoidCallback onAccept;
  final VoidCallback onNegotiate;
  final bool showBestOfferBadge;
  final bool showTopRatedBadge;
  final bool showActionButtons;

  const DriverResponseCard({
    Key? key,
    required this.response,
    required this.onAccept,
    required this.onNegotiate,
    this.showBestOfferBadge = false,
    this.showTopRatedBadge = false,
    this.showActionButtons = false,
  }) : super(key: key);

  @override
  State<DriverResponseCard> createState() => _DriverResponseCardState();
}

class _DriverResponseCardState extends State<DriverResponseCard> {
  bool _showActionButtons = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _showActionButtons = !_showActionButtons;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildDriverInfo(),
              const SizedBox(height: 12),
              _buildDistanceAndTimeInfo(),
              const SizedBox(height: 12),
              _buildVehicleInfo(),
              if (_showActionButtons || widget.showActionButtons) ...[
                const SizedBox(height: 16),
                _buildActionButtons(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage:
              widget.response.driverInfo.profilePhotoUrl.isNotEmpty
                  ? NetworkImage(widget.response.driverInfo.profilePhotoUrl)
                  : null,
          child:
              widget.response.driverInfo.profilePhotoUrl.isEmpty
                  ? const Icon(Icons.person, size: 28)
                  : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.response.driverInfo.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.showTopRatedBadge)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'TOP RATED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.response.driverInfo.rating}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.response.driverInfo.totalRides} rides',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildFareSection(),
      ],
    );
  }

  Widget _buildFareSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.showBestOfferBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'BEST OFFER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          '₹${widget.response.proposedFare.toInt()}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const Text(
          'Proposed Fare',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDriverInfo() {
    final timeAgo = _getTimeAgo(widget.response.timestamp);
    return Row(
      children: [
        const Icon(Icons.access_time, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          'Responded $timeAgo',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const Spacer(),
        const Icon(Icons.phone, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          _formatPhoneNumber(widget.response.driverInfo.phoneNumber),
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDistanceAndTimeInfo() {
    final distance = widget.response.distanceFromUser ?? 0.0;
    final estimatedTime = DriverResponseService.calculateEstimatedTimeMinutes(
      distance,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distance from you',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${distance.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.blue.shade300),
          const SizedBox(width: 12),
          Icon(Icons.schedule, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated arrival',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$estimatedTime min',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getVehicleIcon(widget.response.driverInfo.vehicleType),
            size: 24,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.response.driverInfo.vehicleType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.response.driverInfo.vehicleNumber,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.response.driverInfo.vehicleType,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 1,
          color: Colors.grey.shade300,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onNegotiate,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Negotiate',
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Accept',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'car':
        return Icons.directions_car;
      case 'auto':
        return Icons.airport_shuttle;
      case 'bike':
        return Icons.motorcycle;
      case 'e_rickshaw':
        return Icons.electric_rickshaw;
      default:
        return Icons.directions_car;
    }
  }

  String _formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.length >= 10) {
      return '*******${phoneNumber.substring(phoneNumber.length - 3)}';
    }
    return phoneNumber;
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
