import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'routes/app_router.dart';

/// Sends the user to Dashboard when already authenticated,
/// otherwise to the Home (welcome) screen.
class AuthHandler extends StatelessWidget {
  const AuthHandler({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        final initialRoute =
        snap.hasData ? '/dashboard' : '/'; // Home is '/'

        return Navigator(
          onGenerateRoute: (settings) =>
              AppRouter.generate(RouteSettings(name: initialRoute)),
        );
      },
    );
  }
}
