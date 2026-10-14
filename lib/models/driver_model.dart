class DriverModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? profileImageUrl;
  final double rating;
  final int totalRides;
  final String carModel;
  final String carColor;
  final String carNumber;
  final int totalSeats;
  final double? latitude;
  final double? longitude;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.profileImageUrl,
    required this.rating,
    required this.totalRides,
    required this.carModel,
    required this.carColor,
    required this.carNumber,
    required this.totalSeats,
    this.latitude,
    this.longitude,
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'rating': rating,
      'totalRides': totalRides,
      'carModel': carModel,
      'carColor': carColor,
      'carNumber': carNumber,
      'totalSeats': totalSeats,
      'latitude': latitude,
      'longitude': longitude,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalRides: json['totalRides'] ?? 0,
      carModel: json['carModel'] ?? '',
      carColor: json['carColor'] ?? '',
      carNumber: json['carNumber'] ?? '',
      totalSeats: json['totalSeats'] ?? 4,
      latitude: json['latitude'] != null ? json['latitude'].toDouble() : null,
      longitude:
          json['longitude'] != null ? json['longitude'].toDouble() : null,
      isAvailable: json['isAvailable'] ?? true,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now(),
    );
  }

  // Create a copy with updated values
  DriverModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    double? rating,
    int? totalRides,
    String? carModel,
    String? carColor,
    String? carNumber,
    int? totalSeats,
    double? latitude,
    double? longitude,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      carModel: carModel ?? this.carModel,
      carColor: carColor ?? this.carColor,
      carNumber: carNumber ?? this.carNumber,
      totalSeats: totalSeats ?? this.totalSeats,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
