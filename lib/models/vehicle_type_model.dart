class VehicleType {
  final String id;
  final String name;
  final String iconPath;
  final double baseFare;
  final double farePerKm;
  final int maxPassengers;
  final String description;
  final bool isAvailable;

  VehicleType({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.baseFare,
    required this.farePerKm,
    required this.maxPassengers,
    required this.description,
    this.isAvailable = true,
  });

  // Calculate estimated fare based on distance
  int calculateFare(double distanceKm) {
    return (baseFare + (farePerKm * distanceKm)).toInt();
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconPath': iconPath,
      'baseFare': baseFare,
      'farePerKm': farePerKm,
      'maxPassengers': maxPassengers,
      'description': description,
      'isAvailable': isAvailable,
    };
  }

  // Create from JSON
  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      iconPath: json['iconPath'] ?? '',
      baseFare: (json['baseFare'] ?? 0.0).toDouble(),
      farePerKm: (json['farePerKm'] ?? 0.0).toDouble(),
      maxPassengers: json['maxPassengers'] ?? 1,
      description: json['description'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  // Create a copy with updated values
  VehicleType copyWith({
    String? id,
    String? name,
    String? iconPath,
    double? baseFare,
    double? farePerKm,
    int? maxPassengers,
    String? description,
    bool? isAvailable,
  }) {
    return VehicleType(
      id: id ?? this.id,
      name: name ?? this.name,
      iconPath: iconPath ?? this.iconPath,
      baseFare: baseFare ?? this.baseFare,
      farePerKm: farePerKm ?? this.farePerKm,
      maxPassengers: maxPassengers ?? this.maxPassengers,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VehicleType && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Default vehicle types configuration
class VehicleTypes {
  static List<VehicleType> getDefaultVehicles() {
    return [
      VehicleType(
        id: 'any',
        name: 'Book Any',
        iconPath: 'assets/icons/search.png', // Generic search icon
        baseFare: 10.0,
        farePerKm: 5.0,
        maxPassengers: 4,
        description: 'Any available vehicle',
      ),
      VehicleType(
        id: 'car',
        name: 'Car',
        iconPath: 'assets/icons/car.png', // We'll create this
        baseFare: 15.0,
        farePerKm: 7.0,
        maxPassengers: 4,
        description: 'Comfortable 4-seater car',
      ),
      VehicleType(
        id: 'auto',
        name: 'Auto',
        iconPath: 'assets/icons/auto.png', // We'll create this
        baseFare: 8.0,
        farePerKm: 4.0,
        maxPassengers: 3,
        description: '3-wheeler auto rickshaw',
      ),
      VehicleType(
        id: 'bike',
        name: 'Bike',
        iconPath: 'assets/icons/bike.png', // We'll create this
        baseFare: 5.0,
        farePerKm: 3.0,
        maxPassengers: 1,
        description: 'Fast motorcycle ride',
      ),
      VehicleType(
        id: 'e_rickshaw',
        name: 'E-Rickshaw',
        iconPath: 'assets/icons/e_rickshaw.png', // We'll create this
        baseFare: 6.0,
        farePerKm: 3.5,
        maxPassengers: 3,
        description: 'Eco-friendly electric rickshaw',
      ),
    ];
  }
}
