import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_profile.dart';
import '../widgets/primary_button.dart';
import '../../config/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<UserProfile?>(
        future: AuthService.instance.currentUserProfile(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snap.data!;

          String initials() =>
              user.name.split(' ').map((e) => e[0]).take(2).join();

          return Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // —— Avatar ——————————————————————————
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.primary,
                        child: Text(
                          initials(),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                  
                      // —— Name & e-mail ———————————————
                      Text(user.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(user.email,
                          style: const TextStyle(color: Colors.black54)),
                      Text(user.phone!,
                          style: const TextStyle(color: Colors.black54)),
                  
                      // —— Phone ————————————————
                      // if (user.phone != null && user.phone!.isNotEmpty)
                      //   ListTile(
                      //     leading: const Icon(Icons.phone_outlined),
                      //     title: const Text('Phone'),
                      //     subtitle: Text(user.phone!),
                      //   ),
                  
                      const SizedBox(height: 8),
                  
                      // —— Role chip ————————————————
                      Chip(label: Text(user.role)),
                      const SizedBox(height: 16),
                  
                      // —— Major / Year ——————————————
                      if (user.role != 'Admin' && user.major != null)
                        ListTile(
                          leading: const Icon(Icons.school_outlined),
                          title: const Text('Major'),
                          subtitle: Text(user.major!),
                        ),
                      if (user.role != 'Admin' && user.yearGroup != null)
                        ListTile(
                          leading: const Icon(Icons.calendar_today_outlined),
                          title: const Text('Year Group'),
                          subtitle: Text(user.yearGroup.toString()),
                        ),
                  
                      const SizedBox(height: 24),
                  
                      // —— Logout ————————————————
                      PrimaryButton(
                        outlined: true,
                        label: 'Logout',
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Log out?'),
                              content: const Text(
                                'You will be returned to the landing page.',
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel')),
                                ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Logout')),
                              ],
                            ),
                          );
                  
                          if (ok == true) {
                            await AuthService.instance.logout();
                            if (context.mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                  context, '/', (_) => false);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
