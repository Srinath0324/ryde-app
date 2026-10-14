import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';
import '../main.dart'; // Import to access the useFirebase flag
import 'package:flutter/foundation.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  AuthService? _authService;
  AuthStatus _authStatus = AuthStatus.uninitialized;
  UserModel? _user;
  String? _errorMessage;
  bool _isLoading = false;

  // Mock user for testing - REMOVE: No longer needed since we use _user
  // UserModel? _currentUser;

  // Getters
  AuthStatus get authStatus => _authStatus;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authStatus == AuthStatus.authenticated;
  UserModel? get currentUser => _user;

  AuthProvider() {
    if (useFirebase) {
      _authService = AuthService();
    }
    _initAuthStatus();
  }

  // Initialize auth status
  Future<void> _initAuthStatus() async {
    setLoading(true);

    try {
      if (useFirebase && _authService != null) {
        // Check if user is already authenticated with Firebase
        final currentUser = _authService!.currentUser;

        if (currentUser != null) {
          // User is already signed in
          _user = await _authService!.getUserProfile();
          if (_user != null) {
            _authStatus = AuthStatus.authenticated;
          } else {
            _authStatus = AuthStatus.unauthenticated;
          }
        } else {
          _authStatus = AuthStatus.unauthenticated;
        }
      } else {
        // For demo purposes (when Firebase is not initialized)
        final prefs = await SharedPreferences.getInstance();
        final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

        if (isLoggedIn) {
          // Create a demo user
          _user = UserModel(
            id: '1',
            name: 'User',
            email: 'demo@example.com',
            phoneNumber: '1234567890',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          _authStatus = AuthStatus.authenticated;
        } else {
          _authStatus = AuthStatus.unauthenticated;
        }
      }
    } catch (e) {
      _authStatus = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    } finally {
      setLoading(false);
    }
  }

  // Set loading state
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    if (useFirebase && _authService != null) {
      return await _authService!.emailExists(email);
    }
    return false;
  }

  // Register with email and password
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    String? aadhaarNumber,
    String? gender,
  }) async {
    setLoading(true);
    clearError();

    try {
      if (useFirebase && _authService != null) {
        final userCredential = await _authService!.registerWithEmailAndPassword(
          email,
          password,
          name,
          phoneNumber,
          aadhaarNumber,
          gender,
        );

        if (userCredential.user != null) {
          _user = await _authService!.getUserProfile();
          _authStatus = AuthStatus.authenticated;
          notifyListeners();
          return true;
        }
        return false;
      } else {
        // For demo purposes (when Firebase is not initialized)
        await Future.delayed(
          const Duration(seconds: 1),
        ); // Simulate network delay

        // Create a demo user
        _user = UserModel(
          id: '1',
          name: name,
          email: email,
          phoneNumber: phoneNumber,
          aadhaarNumber: aadhaarNumber,
          gender: gender,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);

        _authStatus = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Sign in with email and password
  Future<bool> signIn({required String email, required String password}) async {
    setLoading(true);
    clearError();

    try {
      if (useFirebase && _authService != null) {
        final userCredential = await _authService!.signInWithEmailAndPassword(
          email,
          password,
        );

        if (userCredential.user != null) {
          _user = await _authService!.getUserProfile();
          _authStatus = AuthStatus.authenticated;
          notifyListeners();
          return true;
        }
        return false;
      } else {
        // For demo purposes (when Firebase is not initialized)
        await Future.delayed(
          const Duration(seconds: 1),
        ); // Simulate network delay

        // Create a demo user
        _user = UserModel(
          id: '1',
          name: ' User',
          email: email,
          phoneNumber: '1234567890',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);

        _authStatus = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Sign in with Google (for existing users)
  Future<bool> signInWithGoogle() async {
    setLoading(true);
    clearError();

    try {
      if (useFirebase && _authService != null) {
        final userCredential = await _authService!.signInWithGoogle();

        if (userCredential?.user != null) {
          _user = await _authService!.getUserProfile();
          _authStatus = AuthStatus.authenticated;
          notifyListeners();
          return true;
        }
        return false;
      } else {
        // For demo purposes (when Firebase is not initialized)
        await Future.delayed(
          const Duration(seconds: 1),
        ); // Simulate network delay

        // Create a demo user
        _user = UserModel(
          id: '1',
          name: 'Google User',
          email: 'google@example.com',
          phoneNumber: '1234567890',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);

        _authStatus = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Sign up with Google (for new users)
  Future<bool> signUpWithGoogle() async {
    setLoading(true);
    clearError();

    try {
      if (useFirebase && _authService != null) {
        final userCredential = await _authService!.signUpWithGoogle();

        if (userCredential?.user != null) {
          _user = await _authService!.getUserProfile();
          _authStatus = AuthStatus.authenticated;
          notifyListeners();
          return true;
        }
        return false;
      } else {
        // For demo purposes (when Firebase is not initialized)
        await Future.delayed(
          const Duration(seconds: 1),
        ); // Simulate network delay

        // Create a demo user
        _user = UserModel(
          id: '1',
          name: 'Google User',
          email: 'google@example.com',
          phoneNumber: '1234567890',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);

        _authStatus = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    setLoading(true);
    clearError();

    try {
      if (useFirebase && _authService != null) {
        await _authService!.signOut();
      }

      // Clear login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      // Don't clear firstTimeKey to avoid showing onboarding again

      _user = null;
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      setLoading(false);
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    setLoading(true);
    clearError();

    try {
      if (useFirebase && _authService != null) {
        await _authService!.sendPasswordResetEmail(email);
      } else {
        // For demo purposes
        await Future.delayed(
          const Duration(seconds: 1),
        ); // Simulate network delay
      }
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Handle Firebase Auth errors
  void _handleAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        _errorMessage = 'This email is already in use by another account.';
        break;
      case 'email-already-driver':
        _errorMessage =
            error.message ??
            'This email is already registered as a driver account. Please use a different email or sign in to the driver app.';
        break;
      case 'email-already-user':
        _errorMessage =
            error.message ??
            'This email is already registered as a user. Please sign in instead.';
        break;
      case 'not-user-account':
        _errorMessage =
            error.message ??
            'This account is not registered as a user. Please sign up as a user first.';
        break;
      case 'not-driver-account':
        _errorMessage =
            'This account is registered as a driver. Please sign in to the driver app instead.';
        break;
      case 'invalid-email':
        _errorMessage = 'Invalid email address.';
        break;
      case 'weak-password':
        _errorMessage = 'The password is too weak.';
        break;
      case 'user-disabled':
        _errorMessage = 'This user has been disabled.';
        break;
      case 'user-not-found':
        _errorMessage = 'Email is not registered, please sign up.';
        break;
      case 'wrong-password':
        _errorMessage = 'Wrong password, try again.';
        break;
      case 'too-many-requests':
        _errorMessage = 'Too many attempts. Try again later.';
        break;
      case 'registration-failed':
        _errorMessage =
            error.message ?? 'Registration failed. Please try again.';
        break;
      case 'not-authenticated':
        _errorMessage = 'Authentication required. Please sign in again.';
        break;
      default:
        _errorMessage = error.message ?? 'An error occurred. Please try again.';
    }
    notifyListeners();
  }

  // Reload user data from Firestore
  Future<bool> reloadUser() async {
    setLoading(true);
    clearError();

    try {
      if (useFirebase && _authService != null) {
        _user = await _authService!.getUserProfile();
        if (_user != null) {
          _authStatus = AuthStatus.authenticated;
          notifyListeners();
          return true;
        }
        return false;
      } else {
        // For demo purposes, do nothing
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      setLoading(false);
    }
  }
}
