import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as ap;
import '../providers/listings_provider.dart';
import 'directory/directory_screen.dart';
import 'listings/my_listings_screen.dart';
import 'map/map_view_screen.dart';
import 'setting/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  Widget _screenForIndex(int index) {
    switch (index) {
      case 0:
        return const DirectoryScreen();
      case 1:
        return const MyListingsScreen();
      case 2:
        return const MapViewScreen();
      default:
        return const SettingsScreen();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<ap.AuthProvider>();
      final listings = context.read<ListingsProvider>();

      final user = auth.user;
      if (user != null) {
        final createdByName = auth.userProfile?.displayName ??
            user.displayName ??
            user.email?.split('@').first ??
            'Community User';
        await listings.ensureStarterListings(
          createdByUid: user.uid,
          createdByName: createdByName,
        );
      }

      listings.subscribeToAllListings();
      if (user != null) listings.subscribeToUserListings(user.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screenForIndex(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Directory'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline),
              activeIcon: Icon(Icons.bookmark),
              label: 'My Listings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Map View'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}
