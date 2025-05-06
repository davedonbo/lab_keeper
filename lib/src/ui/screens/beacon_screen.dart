import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/auth_service.dart';   // if you prefer to fetch profile

class BeaconScreen extends StatefulWidget {
  const BeaconScreen({super.key});
  @override
  State<BeaconScreen> createState() => _BeaconState();
}

class _BeaconState extends State<BeaconScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController ripple;
  StreamSubscription? locSub;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _startBeacon();
    ripple = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();

  }

  Future<void> _startBeacon() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable GPS to broadcast location')),
      );
      return;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
      }
      return;
    }

    locSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      FirebaseFirestore.instance.collection('presence').doc(uid).set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  void dispose() {
    ripple.dispose();
    locSub?.cancel();
    FirebaseFirestore.instance.collection('presence').doc(uid).delete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Proximity Beacon')),
      body: Center(
        child: AnimatedBuilder(
          animation: ripple,
          builder: (_, __) => Stack(
            alignment: Alignment.center,
            children: [
              // -------- THREE RIPPLE WAVES -----------------------------
              for (int i = 0; i < 3; i++)
                _buildWave(
                  progress: (ripple.value + i / 3) % 1,
                  color: scheme.primary,
                ),
              // -------- Static core + icon -----------------------------
              CircleAvatar(
                radius: 35,
                backgroundColor: scheme.primary,
                child: const Icon(Icons.wifi_tethering, color: Colors.white),
              ),
              const Positioned(
                bottom: -60,
                child: Text('Broadcasting location…'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWave({required double progress, required Color color}) {
    final size = 80 + progress * 200;      // min 80 → max 280 px
    return Opacity(
      opacity: 1 - progress,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.2),   // translucent
        ),
      ),
    );
  }


}
