import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart' as ap;
import 'providers/listings_provider.dart';
import 'services/auth_service.dart';
import 'services/listing_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }

  runApp(const KigaliCityApp());
}

class KigaliCityApp extends StatelessWidget {
  const KigaliCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ListingService>(create: (_) => ListingService()),
        ChangeNotifierProxyProvider<AuthService, ap.AuthProvider>(
          create: (ctx) => ap.AuthProvider(ctx.read<AuthService>()),
          update: (_, authService, previous) =>
              previous ?? ap.AuthProvider(authService),
        ),
        ChangeNotifierProxyProvider<ListingService, ListingsProvider>(
          create: (ctx) => ListingsProvider(ctx.read<ListingService>()),
          update: (_, listingService, previous) =>
              previous ?? ListingsProvider(listingService),
        ),
      ],
      child: MaterialApp(
        title: 'Kigali City',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}
