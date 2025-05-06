import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../widgets/password_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/primary_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();         // ← NEW
  final _majorCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  int? _yearGroup;
  bool _loading = false;

  final majors = [
    'Computer Engineering',
    'Computer Science',
    'Business Administration',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Mechatronics Engineering',
    'Law',
    'Economics',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();                               // ← NEW
    _majorCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await AuthService.instance.signUp(
        name     : _nameCtrl.text.trim(),
        email    : _emailCtrl.text.trim(),
        password : _passCtrl.text,
        role     : 'Student',
        major    : _majorCtrl.text.trim(),
        yearGroup: _yearGroup,
        phone    : _phoneCtrl.text.trim(),              // ← NEW
      );

      await AuthService.instance.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. Please log in.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const years = [2025, 2026, 2027, 2028];

    return Scaffold(
      appBar: AppBar(title: const Text('Create an account')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Name
              PrimaryTextField(
                controller: _nameCtrl,
                label: 'Full Name',
                validator: (v) =>
                (v == null || v.trim().length < 2) ? 'Enter a valid name' : null,
              ),
              const SizedBox(height: 16),

              // Email
              PrimaryTextField(
                controller: _emailCtrl,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                (v != null && v.contains('@')) ? null : 'Enter a valid email',
              ),
              const SizedBox(height: 16),

              // Phone
              PrimaryTextField(
                controller: _phoneCtrl,
                label: 'Phone (+233…) ',
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter phone';
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  return digits.length < 9 ? 'Too short' : null;
                },
              ),
              const SizedBox(height: 16),

              // Major dropdown
              DropdownButtonFormField<String>(
                value: majors.contains(_majorCtrl.text) ? _majorCtrl.text : null,
                items: majors
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                decoration: const InputDecoration(
                  labelText: 'Major',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null ? 'Select a major' : null,
                onChanged: (v) => setState(() => _majorCtrl.text = v!),
              ),
              const SizedBox(height: 16),

              // Year group
              DropdownButtonFormField<int>(
                value: _yearGroup,
                items: years
                    .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                    .toList(),
                decoration: const InputDecoration(
                  labelText: 'Year Group',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null ? 'Select year group' : null,
                onChanged: (v) => setState(() => _yearGroup = v),
              ),
              const SizedBox(height: 16),

              // Password / confirm
              PasswordField(
                controller: _passCtrl,
                label: 'Password',
                validator: (v) =>
                (v != null && v.length >= 8) ? null : 'Min 8 characters',
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _confirmCtrl,
                label: 'Confirm Password',
                validator: (v) => v == _passCtrl.text ? null : 'Passwords differ',
              ),
              const SizedBox(height: 24),

              // Submit
              PrimaryButton(
                label: 'Create account',
                loading: _loading,
                onPressed: _loading ? null : _submit,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loading ? null : () => Navigator.pushNamed(context, '/login'),
                child: const Text('Already have an account?  Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
