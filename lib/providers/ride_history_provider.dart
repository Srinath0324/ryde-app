import 'package:flutter/foundation.dart';
import '../models/ride_history_model.dart';
import '../models/ride_request_model.dart';
import '../services/ride_history_service.dart';

class RideHistoryProvider with ChangeNotifier {
  final RideHistoryService _rideHistoryService = RideHistoryService();

  List<RideHistory> _rideHistory = [];
  RideHistory? _latestRide;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<RideHistory> get rideHistory => _rideHistory;
  RideHistory? get latestRide => _latestRide;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasRides => _rideHistory.isNotEmpty;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Add a completed ride to history
  Future<void> addRideToHistory({
    required RideRequest rideRequest,
    required String driverName,
    required int fare,
    required String paymentMethod,
  }) async {
    try {
      await _rideHistoryService.addRideToHistory(
        rideRequest: rideRequest,
        driverName: driverName,
        fare: fare,
        paymentMethod: paymentMethod,
      );

      // Refresh the ride history after adding a new ride
      await loadRideHistory();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  // Load all ride history for the current user
  Future<void> loadRideHistory() async {
    _setLoading(true);
    _setError(null);

    try {
      final rides = await _rideHistoryService.getUserRideHistory();
      _rideHistory = rides;

      if (rides.isNotEmpty) {
        _latestRide = rides.first; // Since the list is already sorted by date
      } else {
        _latestRide = null;
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to load ride history: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load only the most recent ride
  Future<void> loadLatestRide() async {
    _setLoading(true);
    _setError(null);

    try {
      final latest = await _rideHistoryService.getMostRecentRide();
      _latestRide = latest;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load latest ride: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
