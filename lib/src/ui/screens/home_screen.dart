import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../widgets/primary_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return Scaffold(
      body: Column(
        children: [
          // Hero header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 48),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LabKeeper',                        // ← updated
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                  'Borrow engineering components with ease',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Login',
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Sign Up',
                        outlined: true,
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: const [
                _Feature(icon: Icons.book, title: 'Request', text: 'Ask for items'),
                _Feature(icon: Icons.track_changes, title: 'Track', text: 'See status'),
                _Feature(icon: Icons.assignment_returned, title: 'Return', text: 'Bring back'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            width: double.infinity,
            color: AppTheme.secondary,
            child: Column(
              children: [
                Text('© $year LabKeeper',                // ← updated
                    style:
                    Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppTheme.primary),
    title: Text(title),
    subtitle: Text(text),
  );
}