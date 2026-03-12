import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as ap;
import '../../theme/app_theme.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});
  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _pollTimer;
  Timer? _resendTimer;
  bool _canResend = true;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    // Poll Firebase every 3 seconds to detect verification
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        await context.read<ap.AuthProvider>().reloadUser();
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown(int seconds) {
    _resendTimer?.cancel();
    setState(() {
      _canResend = false;
      _resendCountdown = seconds;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      if (_resendCountdown <= 0) {
        t.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    try {
      await context.read<ap.AuthProvider>().sendEmailVerification();
      if (!mounted) return;

      _startResendCooldown(60);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent!')));
    } catch (e) {
      if (!mounted) return;

      final msg = e.toString().toLowerCase();
      if (msg.contains('too-many-requests')) {
        // Firebase temporarily throttles repeated email sends.
        _startResendCooldown(300);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Too many requests. Please wait 5 minutes before resending.')));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send verification email: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<ap.AuthProvider>().user?.email ?? '';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle),
              child: const Icon(Icons.mark_email_unread_outlined,
                  color: AppTheme.accentGold, size: 44),
            ),
            const SizedBox(height: 28),
            const Text('Verify Your Email',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            Text('We\'ve sent a verification email to\n$email',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary, height: 1.5)),
            const SizedBox(height: 8),
            const Text(
              'Verify your email to continue. '
              'The app will automatically detect verification.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 36),
            ElevatedButton.icon(
              onPressed: _canResend ? _resend : null,
              icon: const Icon(Icons.refresh),
              label: Text(_canResend
                  ? 'Resend Verification Email'
                  : 'Resend in ${_resendCountdown}s'),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => context.read<ap.AuthProvider>().signOut(),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign Out'),
            ),
          ]),
        ),
      ),
    );
  }
}
