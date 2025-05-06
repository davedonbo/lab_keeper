import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../widgets/password_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/primary_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      // 1. Sign in to Firebase Auth
      await AuthService.instance
          .login(_emailCtrl.text.trim(), _passCtrl.text);

      // 2. Fetch the Firestore profile → check role
      final profile = await AuthService.instance.currentUserProfile();
      if (!mounted) return;

      final targetRoute =
      (profile?.role == 'Admin') ? '/admin' : '/dashboard';

      // 3. Navigate to the correct page
      Navigator.pushNamedAndRemoveUntil(context, targetRoute, (_) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              PrimaryTextField(
                controller: _emailCtrl,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter your email';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _passCtrl,
                label: 'Password',
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Enter your password' : null,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Login',
                loading: _loading,
                onPressed: _loading ? null : _submit,
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => Navigator.pushNamed(context, '/signup'),
                child: const Text('Create account'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
