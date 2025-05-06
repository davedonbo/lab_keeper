import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  Stream<User?> get onAuthStateChanged => _auth.authStateChanges();

  Future<UserProfile?> currentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final snap = await _db.collection('users').doc(user.uid).get();
    return UserProfile.fromJson(user.uid, snap.data()!);
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    String? major,
    int? yearGroup,
    String? phone,                       // ← NEW
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _db.collection('users').doc(cred.user!.uid).set({
      'name'     : name,
      'email'    : email,
      'role'     : role,
      'major'    : major,
      'yearGroup': yearGroup,
      'phone'    : phone,                // ← NEW
    });
  }


  Future<void> login(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> logout() => _auth.signOut();
}
