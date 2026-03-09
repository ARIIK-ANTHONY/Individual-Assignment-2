import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as ap;
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'auth/email_verification_screen.dart';
import 'home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ap.AuthProvider>(
      builder: (_, auth, __) {
        switch (auth.status) {
          case ap.AuthStatus.initial:
          case ap.AuthStatus.loading:
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.accentGold,
                      child: Icon(Icons.location_city_rounded,
                          color: AppTheme.primaryDark, size: 36),
                    ),
                    SizedBox(height: 20),
                    CircularProgressIndicator(color: AppTheme.accentGold),
                  ],
                ),
              ),
            );
          case ap.AuthStatus.authenticated:
            if (!auth.isEmailVerified) return const EmailVerificationScreen();
            return const HomeScreen();
          case ap.AuthStatus.unauthenticated:
          case ap.AuthStatus.error:
            return const LoginScreen();
        }
      },
    );
  }
}
