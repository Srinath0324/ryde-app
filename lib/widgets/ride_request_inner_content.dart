import 'package:flutter/material.dart';

class RideRequestInnerContent extends StatelessWidget {
  final String vehicleType;

  const RideRequestInnerContent({Key? key, required this.vehicleType})
    : super(key: key);

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'any':
        return Icons.search;
      case 'car':
        return Icons.directions_car;
      case 'bike':
        return Icons.two_wheeler;
      case 'auto':
        return Icons.agriculture;
      case 'e_rickshaw':
        return Icons.electric_rickshaw;
      default:
        return Icons.directions_car;
    }
  }

  String _getVehicleDisplayName(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'any':
        return 'Book Any';
      case 'car':
        return 'Car';
      case 'bike':
        return 'Bike';
      case 'auto':
        return 'Auto';
      case 'e_rickshaw':
        return 'E-Rickshaw';
      default:
        return 'Car';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getVehicleIcon(vehicleType),
            color: Colors.blue[700],
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _getVehicleDisplayName(vehicleType),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
