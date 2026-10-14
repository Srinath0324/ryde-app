import 'package:cloud_firestore/cloud_firestore.dart';

class Wallet {
  final String userId;
  final int balance;
  final DateTime lastUpdated;

  Wallet({
    required this.userId,
    required this.balance,
    required this.lastUpdated,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'balance': balance,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Create from Firestore JSON
  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      userId: json['userId'] ?? '',
      balance: json['balance'] ?? 0,
      lastUpdated:
          json['lastUpdated'] != null
              ? DateTime.parse(json['lastUpdated'])
              : DateTime.now(),
    );
  }

  // Create a copy with updated values
  Wallet copyWith({String? userId, int? balance, DateTime? lastUpdated}) {
    return Wallet(
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class WalletTransaction {
  final String id;
  final String userId;
  final String title;
  final int amount;
  final DateTime date;
  final bool isCredit;

  WalletTransaction({
    String? id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.date,
    this.isCredit = true,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'isCredit': isCredit,
    };
  }

  // Create from Firestore JSON
  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      amount: json['amount'] ?? 0,
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      isCredit: json['isCredit'] ?? true,
    );
  }
}
