import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../main.dart';
import '../../models/borrow_request.dart';
import '../../models/borrow_status.dart';
import '../../services/auth_service.dart';
import '../widgets/request_return_page.dart';
import '../widgets/request_review_page.dart';
import '../widgets/returned_detail_page.dart';
import '../widgets/student_request_detail_page.dart';

/// then decides where to navigate based on auth & role.
class SplashScreen extends StatefulWidget {
  final String? pendingRequestId;
  const SplashScreen({this.pendingRequestId, super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(seconds: 3));

    final user = FirebaseAuth.instance.currentUser;
    String route;
    if (user == null) {
      route = '/home';
    } else {
      final profile = await AuthService.instance.currentUserProfile();
      route = profile?.role == 'Admin' ? '/admin' : '/dashboard';
    }

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
    }

    if (widget.pendingRequestId != null) {
      // give one frame to ensure navigator is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationTap(widget.pendingRequestId!);
      });
    }
  }

  Future<void> _handleNotificationTap(String requestId) async {
    // Fetch the latest request document
    final doc = await FirebaseFirestore.instance
        .collection('borrow_requests')
        .doc(requestId)
        .get();
    if (!doc.exists) return;

    // Parse into your model
    final request = BorrowRequest.fromJson(
      doc.id,
      doc.data()! as Map<String, dynamic>,
    );

    final profile = await AuthService.instance.currentUserProfile();

    if(profile == null) return;

    late Widget page;
    if(profile.role == 'Admin'){
      switch (request.status) {
        case BorrowStatus.pending:
          page = RequestReviewPage(request: request);
          break;
        case BorrowStatus.approved:
          page = ReturnReviewPage(request: request);
          break;
        case BorrowStatus.returned:
          page = ReturnedDetailPage(request: request);
          break;
        default:
          page = ReturnedDetailPage(request: request);
      }
    }
    else{
      page = StudentRequestDetailPage(request: request);
    }

    // Navigate on the root navigator
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔧 gear/robotic‑arm icon instead of chemistry beaker
            Icon(Icons.precision_manufacturing,
                size: 96, color: Colors.white),
            const SizedBox(height: 16),
            Text('LabKeeper',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white)),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
