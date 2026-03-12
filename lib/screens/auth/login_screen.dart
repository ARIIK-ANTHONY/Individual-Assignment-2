import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as ap;
import '../../theme/app_theme.dart';
import 'signup_screen.dart';
import 'email_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final auth = context.read<ap.AuthProvider>();
    final success = await auth.signIn(
        email: _emailCtrl.text.trim(), password: _passCtrl.text);
    if (!mounted) return;
    if (success) {
      await auth.reloadUser();
      if (!mounted) return;
      if (!auth.isEmailVerified) {
        navigator.pushReplacement(
            MaterialPageRoute(builder: (_) => const EmailVerificationScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Center(
                  child: Column(children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                          color: AppTheme.accentGold,
                          borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.location_city_rounded,
                          color: AppTheme.primaryDark, size: 40),
                    ),
                    const SizedBox(height: 20),
                    const Text('Kigali City',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 6),
                    const Text('Services & Places Directory',
                        style: TextStyle(
                            fontSize: 14, color: AppTheme.textSecondary)),
                  ]),
                ),
                const SizedBox(height: 48),
                const Text('Welcome back',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                const Text('Sign in to continue',
                    style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 32),

                // Error banner
                Consumer<ap.AuthProvider>(builder: (_, auth, __) {
                  if (auth.errorMessage == null) return const SizedBox();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.errorRed.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.errorRed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(auth.errorMessage!,
                              style: const TextStyle(
                                  color: AppTheme.errorRed, fontSize: 13))),
                    ]),
                  );
                }),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                      hintText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Password is required' : null,
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPassword,
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 16),

                Consumer<ap.AuthProvider>(
                  builder: (_, auth, __) => ElevatedButton(
                    onPressed: auth.isLoading ? null : _login,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: AppTheme.primaryDark))
                        : const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 24),

                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("Don't have an account? ",
                      style: TextStyle(color: AppTheme.textSecondary)),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignupScreen())),
                    child: const Text('Sign Up'),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPassword() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Reset Password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Enter your email to receive a reset link.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          TextFormField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(hintText: 'Email address')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                final authService = context.read<ap.AuthProvider>().authService;
                final messenger = ScaffoldMessenger.of(context);
                final dialogNavigator = Navigator.of(ctx);
                try {
                  await authService.sendPasswordResetEmail(ctrl.text.trim());
                  if (!mounted) return;
                  dialogNavigator.pop();
                  messenger.showSnackBar(
                      const SnackBar(content: Text('Reset email sent!')));
                } catch (e) {
                  if (!mounted) return;
                  dialogNavigator.pop();
                  messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
