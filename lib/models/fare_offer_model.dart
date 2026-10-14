class FareOffer {
  final String id;
  final String riderId;
  final String driverId;
  final double amount;
  final DateTime timestamp;
  final String status; // 'pending', 'accepted', 'rejected', 'countered'
  final String? message;

  FareOffer({
    required this.id,
    required this.riderId,
    required this.driverId,
    required this.amount,
    required this.timestamp,
    required this.status,
    this.message,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'riderId': riderId,
      'driverId': driverId,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'message': message,
    };
  }

  // Create from JSON
  factory FareOffer.fromJson(Map<String, dynamic> json) {
    return FareOffer(
      id: json['id'] ?? '',
      riderId: json['riderId'] ?? '',
      driverId: json['driverId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      timestamp:
          json['timestamp'] != null
              ? DateTime.parse(json['timestamp'])
              : DateTime.now(),
      status: json['status'] ?? 'pending',
      message: json['message'],
    );
  }

  // Create a copy with updated values
  FareOffer copyWith({
    String? id,
    String? riderId,
    String? driverId,
    double? amount,
    DateTime? timestamp,
    String? status,
    String? message,
  }) {
    return FareOffer(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      driverId: driverId ?? this.driverId,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}
