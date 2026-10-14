class RideHistory {
  final String id;
  final String riderId;
  final String? driverId;
  final String fromAddress;
  final String toAddress;
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final int fare;
  final DateTime dateTime;
  final String driverName;
  final int seats;
  final String status; // 'Paid', 'Cancelled', etc.
  final String rideType; // 'shared' or 'private'
  final String paymentMethod; // 'cash' or 'wallet'

  RideHistory({
    required this.id,
    required this.riderId,
    this.driverId,
    required this.fromAddress,
    required this.toAddress,
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
    required this.fare,
    required this.dateTime,
    required this.driverName,
    required this.seats,
    required this.status,
    required this.rideType,
    required this.paymentMethod,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'riderId': riderId,
      'driverId': driverId,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'fromLat': fromLat,
      'fromLng': fromLng,
      'toLat': toLat,
      'toLng': toLng,
      'fare': fare,
      'dateTime': dateTime.toIso8601String(),
      'driverName': driverName,
      'seats': seats,
      'status': status,
      'rideType': rideType,
      'paymentMethod': paymentMethod,
    };
  }

  // Create from JSON
  factory RideHistory.fromJson(Map<String, dynamic> json) {
    return RideHistory(
      id: json['id'] ?? '',
      riderId: json['riderId'] ?? '',
      driverId: json['driverId'],
      fromAddress: json['fromAddress'] ?? '',
      toAddress: json['toAddress'] ?? '',
      fromLat: (json['fromLat'] ?? 0.0).toDouble(),
      fromLng: (json['fromLng'] ?? 0.0).toDouble(),
      toLat: (json['toLat'] ?? 0.0).toDouble(),
      toLng: (json['toLng'] ?? 0.0).toDouble(),
      fare: (json['fare'] ?? 0).toInt(),
      dateTime:
          json['dateTime'] != null
              ? DateTime.parse(json['dateTime'])
              : DateTime.now(),
      driverName: json['driverName'] ?? '',
      seats: json['seats'] ?? 1,
      status: json['status'] ?? 'Paid',
      rideType: json['rideType'] ?? 'shared',
      paymentMethod: json['paymentMethod'] ?? 'cash',
    );
  }

  // Create a copy with updated values
  RideHistory copyWith({
    String? id,
    String? riderId,
    String? driverId,
    String? fromAddress,
    String? toAddress,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    int? fare,
    DateTime? dateTime,
    String? driverName,
    int? seats,
    String? status,
    String? rideType,
    String? paymentMethod,
  }) {
    return RideHistory(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      driverId: driverId ?? this.driverId,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      fromLat: fromLat ?? this.fromLat,
      fromLng: fromLng ?? this.fromLng,
      toLat: toLat ?? this.toLat,
      toLng: toLng ?? this.toLng,
      fare: fare ?? this.fare,
      dateTime: dateTime ?? this.dateTime,
      driverName: driverName ?? this.driverName,
      seats: seats ?? this.seats,
      status: status ?? this.status,
      rideType: rideType ?? this.rideType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
