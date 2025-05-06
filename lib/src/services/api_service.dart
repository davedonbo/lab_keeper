import 'dart:async';
import '../models/equipment.dart';

class ApiService {
  ApiService._();
  static final instance = ApiService._();

  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    // TODO implement real login
    return true;
  }

  Future<bool> signup(Map<String, dynamic> body) async {
    await Future.delayed(const Duration(seconds: 1));
    // TODO implement real signup
    return true;
  }

  Future<List<Equipment>> getEquipment() async {
    await Future.delayed(const Duration(seconds: 1));
    // TODO fetch from backend
    return [];
  }
}
