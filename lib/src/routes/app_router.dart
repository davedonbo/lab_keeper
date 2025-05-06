import 'package:flutter/material.dart';
import 'package:lab_keeper/src/ui/screens/beacon_screen.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/signup_screen.dart';
import '../ui/screens/dashboard_screen.dart';
import '../ui/screens/borrow_screen.dart';
import '../ui/screens/admin_screen.dart';
import '../ui/screens/add_equipment_screen.dart';
import '../ui/screens/logs_screen.dart';
import '../ui/screens/profile_screen.dart';

class AppRouter {
  static Route<dynamic> generate(RouteSettings s) {
    switch (s.name) {
      case '/home':
        return _page(const HomeScreen());
      case '/login':
        return _page(const LoginScreen());
      case '/signup':
        return _page(const SignupScreen());
      case '/dashboard':
        return _page(const DashboardScreen());
      case '/borrow':
        return _page(const BorrowScreen());
      case '/admin':
        return _page(const AdminScreen());
      case '/admin/add':
        return _page(const AddEquipmentScreen());
      case '/admin/logs':
        return _page(const LogsScreen());
      case '/beacon':
        return _page(const BeaconScreen());
      case '/profile':
        return _page(const ProfileScreen());
      default:
        return _page(Scaffold(
          body: Center(child: Text('No route for ${s.name}')),
        ));
    }
  }

  static MaterialPageRoute _page(Widget child) =>
      MaterialPageRoute(builder: (_) => child);
}
