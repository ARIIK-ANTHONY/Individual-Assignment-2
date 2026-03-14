import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart' as ap;
import 'providers/listings_provider.dart';
import 'services/auth_service.dart';
import 'services/listing_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth_wrapper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error: $error');
    return true;
  };

  ErrorWidget.builder = (details) => Material(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Something went wrong. Please return to the previous screen.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
        ),
      );

  runZonedGuarded(
    () => runApp(const KigaliCityApp()),
    (error, stackTrace) {
      debugPrint('Uncaught zone error: $error');
    },
  );
}

class KigaliCityApp extends StatelessWidget {
  const KigaliCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kigali City',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const _FirebaseBootstrapScreen(),
    );
  }
}

class _FirebaseBootstrapScreen extends StatefulWidget {
  const _FirebaseBootstrapScreen();

  @override
  State<_FirebaseBootstrapScreen> createState() =>
      _FirebaseBootstrapScreenState();
}

class _FirebaseBootstrapScreenState extends State<_FirebaseBootstrapScreen> {
  late Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') {
        rethrow;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.accentGold),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off,
                        color: AppTheme.errorRed, size: 36),
                    const SizedBox(height: 12),
                    const Text(
                      'Failed to initialize app services',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _bootstrapFuture = _initializeFirebase();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

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
          child: const AuthWrapper(),
        );
      },
    );
  }
}
