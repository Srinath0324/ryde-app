class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? aadhaarNumber;
  final String? gender;
  final String? profileImageUrl;
  final bool isVerified;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.aadhaarNumber,
    this.gender,
    this.profileImageUrl,
    this.isVerified = false,
    this.role = 'user',
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'aadhaarNumber': aadhaarNumber,
      'gender': gender,
      'profileImageUrl': profileImageUrl,
      'isVerified': isVerified,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      aadhaarNumber: json['aadhaarNumber'],
      gender: json['gender'],
      profileImageUrl: json['profileImageUrl'],
      isVerified: json['isVerified'] ?? false,
      role: json['role'] ?? 'user',
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
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? aadhaarNumber,
    String? gender,
    String? profileImageUrl,
    bool? isVerified,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      gender: gender ?? this.gender,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isVerified: isVerified ?? this.isVerified,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
