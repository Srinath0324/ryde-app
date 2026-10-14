import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'constants/app_routes.dart';
import 'constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/ride_provider.dart';
import 'providers/ride_history_provider.dart';
import 'providers/driver_response_provider.dart';
import 'providers/dynamic_fare_provider.dart';
import 'services/map_service.dart';
import 'services/fcm_service.dart';
import 'services/notification_service.dart';
import 'services/ride_request_service.dart';
import 'services/active_ride_service.dart';
import 'services/fare_config_setup_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ride_history_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/book_ride_screen.dart';
import 'screens/tracking_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/user_to_driver_matching_screen.dart';
import 'widgets/persistent_bottom_nav.dart';
import 'firebase_options.dart';

// Flag to control Firebase initialization
bool useFirebase = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize MapBox SDK
  await MapService.initialize();

  // Initialize Firebase if needed
  if (useFirebase) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully');

      // Initialize FCM
      await FCMService.initialize();

      // Initialize local notifications
      await NotificationService.initialize();

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Setup message listeners
      FCMService.listenForForegroundMessages();
      FCMService.listenForMessageOpenedApp();

      print('FCM initialized successfully');

      // Clean up expired ride requests on app startup
      RideRequestService.cleanupExpiredDocuments();

      // Initialize Firestore collections (city_configs and fare_configs)
      try {
        print('🚀 Initializing Firestore collections...');
        await FareConfigSetupService.initializeDefaultConfigurations();
        print('✅ Firestore collections initialized successfully');
      } catch (e) {
        print('⚠️ Error initializing Firestore collections: $e');
        print('Note: Collections may already exist or will be created on first use');
      }
    } catch (e) {
      print('Failed to initialize Firebase: $e');
    }
  }

  runApp(const RydeApp());
}

class RydeApp extends StatefulWidget {
  const RydeApp({super.key});

  @override
  State<RydeApp> createState() => _RydeAppState();
}

class _RydeAppState extends State<RydeApp> {
  @override
  void dispose() {
    // Clean up active ride service
    ActiveRideService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => RideProvider()),
        ChangeNotifierProvider(create: (_) => RideHistoryProvider()),
        ChangeNotifierProvider(create: (_) => DriverResponseProvider()),
        ChangeNotifierProvider(create: (_) => DynamicFareProvider()),
      ],
      child: MaterialApp(
        title: 'Ryde',
        theme: AppTheme.getTheme(),
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (context) => const SplashScreen(),
          AppRoutes.onboarding: (context) => const OnboardingScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.signup: (context) => const SignupScreen(),
          AppRoutes.home: (context) => const PersistentBottomNav(),
          AppRoutes.profile: (context) => const ProfileScreen(),
          AppRoutes.rideHistory: (context) => const RideHistoryScreen(),
          AppRoutes.chat: (context) => const ChatScreen(),
          AppRoutes.bookRide: (context) => const BookRideScreen(),
          AppRoutes.tracking: (context) => const TrackingScreen(),
          AppRoutes.wallet: (context) => const WalletScreen(),
          AppRoutes.userToDriverMatching:
              (context) => UserToDriverMatchingScreen(),
        },
      ),
    );
  }
}
