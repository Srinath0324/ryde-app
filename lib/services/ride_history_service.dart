import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_history_model.dart';
import '../models/ride_request_model.dart';
import '../constants/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class RideHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Add a ride to user's ride history
  Future<void> addRideToHistory({
    required RideRequest rideRequest,
    required String driverName,
    required int fare,
    required String paymentMethod,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Create a new ride history entry using new model structure
      final rideHistory = RideHistory(
        id: _uuid.v4(),
        riderId: currentUserId!,
        driverId: rideRequest.selectedDriverId,
        fromAddress: rideRequest.fromAddress,
        toAddress: rideRequest.toAddress,
        fromLat: rideRequest.fromLocation.latitude,
        fromLng: rideRequest.fromLocation.longitude,
        toLat: rideRequest.toLocation.latitude,
        toLng: rideRequest.toLocation.longitude,
        fare: fare,
        dateTime: DateTime.now(),
        driverName: driverName,
        seats: rideRequest.seats,
        status: 'Paid',
        rideType: rideRequest.rideType,
        paymentMethod: paymentMethod,
      );

      // Save to Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .collection('ride_history')
          .doc(rideHistory.id)
          .set(rideHistory.toJson());

      return;
    } catch (e) {
      rethrow;
    }
  }

  // Get all rides for the current user
  Future<List<RideHistory>> getUserRideHistory() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot =
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(currentUserId)
              .collection('ride_history')
              .orderBy('dateTime', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => RideHistory.fromJson(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get the most recent ride for the current user
  Future<RideHistory?> getMostRecentRide() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot =
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(currentUserId)
              .collection('ride_history')
              .orderBy('dateTime', descending: true)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return RideHistory.fromJson(snapshot.docs.first.data());
    } catch (e) {
      rethrow;
    }
  }
}
