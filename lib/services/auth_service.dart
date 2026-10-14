import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Check if email exists in Firebase
  Future<bool> emailExists(String email) async {
    try {
      // Using Firestore to check if user exists instead of deprecated method
      final userDoc =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
      return userDoc.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Check user role in Firestore (users vs drivers)
  Future<String?> getUserRole(String email) async {
    try {
      print('Checking role for email: $email');

      // Check in drivers collection first
      final driverQuery =
          await _firestore
              .collection('drivers')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (driverQuery.docs.isNotEmpty) {
        print('Found user in drivers collection');
        return 'driver';
      }

      // Check in users collection
      final userQuery =
          await _firestore
              .collection(AppConstants.usersCollection)
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (userQuery.docs.isNotEmpty) {
        print('Found user in users collection');
        return 'user';
      }

      print('No role found for email: $email');
      return null; // No role found
    } catch (e) {
      print('Error checking user role: $e');
      return null;
    }
  }

  // Check if user exists and has user role
  Future<bool> isUserAccount(String email) async {
    try {
      final role = await getUserRole(email);
      return role == 'user';
    } catch (e) {
      print('Error checking user account: $e');
      return false;
    }
  }

  // Check if email can be used for user registration
  Future<bool> canRegisterAsUser(String email) async {
    try {
      final existsInAuth = await emailExists(email);

      if (existsInAuth) {
        final role = await getUserRole(email);

        if (role == 'driver') {
          return false; // Email is already registered as a driver
        } else if (role == 'user') {
          return false; // Email is already registered as a user
        }
        return true; // Exists in Auth but no role (incomplete registration)
      }

      return true; // Email doesn't exist, can register
    } catch (e) {
      print('Error checking if can register as user: $e');
      return false;
    }
  }

  // Similar method for Google registration
  Future<bool> canRegisterAsUserWithGoogle(String email) async {
    try {
      final role = await getUserRole(email);

      if (role == 'driver') {
        return false; // Email is already registered as a driver
      } else if (role == 'user') {
        return false; // Email is already registered as a user
      }

      return true; // Email is not used or no role found
    } catch (e) {
      print('Error checking if can register as user with Google: $e');
      return false;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String phoneNumber,
    String? aadhaarNumber,
    String? gender,
  ) async {
    try {
      print('Starting user registration for: $email');

      // Check if email can be used for user registration
      final canRegister = await canRegisterAsUser(email);
      if (!canRegister) {
        final role = await getUserRole(email);
        if (role == 'driver') {
          throw FirebaseAuthException(
            code: 'email-already-driver',
            message:
                'This email is already registered as a driver account. Please use a different email or sign in to the driver app.',
          );
        } else if (role == 'user') {
          throw FirebaseAuthException(
            code: 'email-already-user',
            message:
                'This email is already registered as a user. Please sign in instead.',
          );
        } else {
          throw FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'The email address is already in use by another account.',
          );
        }
      }

      // Create user in Firebase Auth
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Create user profile in Firestore
      if (userCredential.user != null) {
        final now = DateTime.now();
        final String userId = userCredential.user!.uid;

        // Store in USERS collection with role='user'
        final UserModel user = UserModel(
          id: userId,
          name: name,
          email: email,
          phoneNumber: phoneNumber,
          aadhaarNumber: aadhaarNumber,
          gender: gender,
          role: 'user', // Critical: Set role as 'user'
          isVerified: false,
          createdAt: now,
          updatedAt: now,
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .set(user.toJson());

        // Save user ID to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userIdKey, userId);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print(
        'FirebaseAuthException during user registration: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      print('General error during user registration: $e');
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'User registration failed: ${e.toString()}',
      );
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('Attempting user sign in for: $email');

      // First check if this is a user account
      final isUser = await isUserAccount(email);
      if (!isUser) {
        final role = await getUserRole(email);
        if (role == 'driver') {
          throw FirebaseAuthException(
            code: 'not-user-account',
            message:
                'This account is registered as a driver. Please sign in to the driver app instead.',
          );
        } else {
          throw FirebaseAuthException(
            code: 'not-user-account',
            message:
                'This account is not registered as a user. Please sign up as a user first.',
          );
        }
      }

      // Proceed with Firebase Auth sign in
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      // Save user ID to shared preferences
      if (userCredential.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userIdKey, userCredential.user!.uid);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print(
        'FirebaseAuthException during user sign in: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      print('General error during user sign in: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Start the Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in flow
        return null;
      }

      print('Attempting Google sign in for: ${googleUser.email}');

      // Check if this is a user account
      final isUser = await isUserAccount(googleUser.email);
      if (!isUser) {
        await _googleSignIn.signOut();
        final role = await getUserRole(googleUser.email);
        if (role == 'driver') {
          throw FirebaseAuthException(
            code: 'not-user-account',
            message:
                'This Google account is registered as a driver. Please sign in to the driver app instead.',
          );
        } else {
          throw FirebaseAuthException(
            code: 'not-user-account',
            message:
                'This Google account is not registered as a user. Please sign up as a user first.',
          );
        }
      }

      // Get the authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Save user ID to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userIdKey, userCredential.user!.uid);

      return userCredential;
    } catch (e) {
      print('Error in Google sign in: $e');
      rethrow;
    }
  }

  // Google Sign-Up (for registration)
  Future<UserCredential?> signUpWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      print('Attempting Google sign up for: ${googleUser.email}');

      // Check if email can be used for user registration
      final canRegister = await canRegisterAsUserWithGoogle(googleUser.email);
      if (!canRegister) {
        await _googleSignIn.signOut();
        final role = await getUserRole(googleUser.email);
        if (role == 'driver') {
          throw FirebaseAuthException(
            code: 'email-already-driver',
            message:
                'This Google account is already registered as a driver. Please use a different Google account or sign in to the driver app.',
          );
        } else if (role == 'user') {
          throw FirebaseAuthException(
            code: 'email-already-user',
            message:
                'This Google account is already registered as a user. Please sign in instead.',
          );
        }
      }

      // Continue with Google authentication...
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Check if this is a new user and create profile
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser && userCredential.user != null) {
        // Create a new user profile in Firestore
        final now = DateTime.now();
        final user = UserModel(
          id: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'User',
          email: userCredential.user!.email ?? '',
          phoneNumber: userCredential.user!.phoneNumber ?? '',
          profileImageUrl: userCredential.user!.photoURL,
          role: 'user', // Critical: Set role as 'user'
          isVerified: userCredential.user!.emailVerified,
          createdAt: now,
          updatedAt: now,
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userCredential.user!.uid)
            .set(user.toJson());
      }

      // Save user ID to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userIdKey, userCredential.user!.uid);

      return userCredential;
    } catch (e) {
      print('Error in Google sign up: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // Sign out from Google
      await _auth.signOut(); // Sign out from Firebase

      // Clear user ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userIdKey);
    } catch (e) {
      rethrow;
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile() async {
    try {
      if (currentUser == null) return null;

      final DocumentSnapshot userDoc =
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(currentUser!.uid)
              .get();

      if (userDoc.exists) {
        return UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .update(user.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }
}
