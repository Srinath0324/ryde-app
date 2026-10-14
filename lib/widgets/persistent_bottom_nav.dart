import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/ride_history_screen.dart';
import '../screens/wallet_screen.dart';
import '../screens/chat_screen.dart';
import 'bottom_navbar.dart';
import 'persistent_tracking_banner.dart';
import '../constants/app_routes.dart';

class PersistentBottomNav extends StatefulWidget {
  const PersistentBottomNav({Key? key}) : super(key: key);

  @override
  State<PersistentBottomNav> createState() => _PersistentBottomNavState();
}

class _PersistentBottomNavState extends State<PersistentBottomNav> {
  int _currentIndex = 0;

  // List of screens to be shown in the bottom navigation
  final List<Widget> _screens = [
    const HomeScreen(),
    const RideHistoryScreen(),
    const WalletScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  String _getCurrentRouteName() {
    switch (_currentIndex) {
      case 0:
        return AppRoutes.home;
      case 1:
        return AppRoutes.rideHistory;
      case 2:
        return AppRoutes.wallet;
      case 3:
        return AppRoutes.chat;
      case 4:
        return AppRoutes.profile;
      default:
        return AppRoutes.home;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTrackingBanner(
      currentRouteName: _getCurrentRouteName(),
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
