import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class EquipmentService {
  EquipmentService._();
  static final instance = EquipmentService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection('equipment');

  Future<void> addEquipment(String name, UserProfile admin) async {
    await _col.add({'name': name});
    await _log(admin.uid, 'Create', 'Equipment added: $name');
  }

  Future<void> updateEquipment(String docId, String name, UserProfile admin) async {
    await _col.doc(docId).update({'name': name});
    await _log(admin.uid, 'Update', 'Equipment updated: $docId');
  }

  Future<void> deleteEquipment(String docId, UserProfile admin) async {
    final doc = await _col.doc(docId).get();           // read once
    final name = doc['name'] ?? docId;                 // fallback to id

    await _col.doc(docId).delete();                    // delete
    await _log(admin.uid, 'Delete', 'Equipment deleted: $name'); // save name
  }

  Stream<QuerySnapshot> streamAll() => _col.snapshots();

  Future<void> _log(String uid, String action, String details) async {
    final adminSnap =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final adminName = adminSnap['name'] ?? 'Unknown';

    await FirebaseFirestore.instance.collection('audit_logs').add({
      'userID'   : uid,
      'userName' : adminName,          // ← NEW
      'action'   : action,
      'details'  : details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
