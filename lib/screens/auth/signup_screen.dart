import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as ap;
import '../../theme/app_theme.dart';
import 'email_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _confirmEmailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _confirmEmailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<ap.AuthProvider>();
    final success = await auth.signUp(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      displayName: _nameCtrl.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const EmailVerificationScreen()));
      return;
    }

    final message = auth.errorMessage?.toLowerCase() ?? '';
    if (message.contains('already exists') ||
        message.contains('already in use')) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Account Already Exists'),
          content: const Text(
            'This email is already registered. Sign in and use "Resend Verification Email" if your email is not verified yet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Stay Here'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Go To Sign In'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 12),
              const Text('Join Kigali City',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              const Text('Create your account to explore and list services',
                  style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 32),
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
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  if (v.trim().length < 2) return 'Name too short';
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
                controller: _confirmEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'Confirm email address',
                    prefixIcon: Icon(Icons.alternate_email_outlined)),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please confirm your email';
                  }
                  final email = _emailCtrl.text.trim().toLowerCase();
                  final confirm = v.trim().toLowerCase();
                  if (confirm != email) return 'Email addresses do not match';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Confirm password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm password';
                  if (v != _passCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Consumer<ap.AuthProvider>(
                builder: (_, auth, __) => ElevatedButton(
                  onPressed: auth.isLoading ? null : _signUp,
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: AppTheme.primaryDark))
                      : const Text('Create Account'),
                ),
              ),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Already have an account? ',
                    style: TextStyle(color: AppTheme.textSecondary)),
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Sign In')),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
