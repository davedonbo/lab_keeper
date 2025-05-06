import 'package:cloud_firestore/cloud_firestore.dart';

class AuditService {
  AuditService._();
  static final instance = AuditService._();

  Stream<QuerySnapshot> streamAll() =>
      FirebaseFirestore.instance.collection('audit_logs')
          .orderBy('timestamp', descending: true)
          .snapshots();
}
