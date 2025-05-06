import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class BorrowService {
  BorrowService._();
  static final instance = BorrowService._();

  final _db = FirebaseFirestore.instance;

  Future<void> requestEquipment({
    required UserProfile student,
    required List<Map<String, dynamic>> items,  // {equipmentId, qty, desc?}
    required DateTime collectionDateTime,
  }) async {
    await _db.runTransaction((tx) async {
      final reqRef = _db.collection('borrow_requests').doc();
      tx.set(reqRef, {
        'userID': student.uid,
        'status': 'Pending',
        'borrowDate': FieldValue.serverTimestamp(),
        'collectionDateTime': collectionDateTime,
      });

      final itemsCol = reqRef.collection('items');
      for (var it in items) {
        tx.set(itemsCol.doc(), {
          'equipmentID': it['equipmentId'],
          'quantity': it['qty'],
          'description': it['desc'],
          'serialNumber': null,
        });
      }

      // _addAudit(tx, student.uid, 'Borrow', 'Request ${reqRef.id} created');
    });

    // trigger email via callable CF if you want
    // await FirebaseFunctions.instance.httpsCallable('sendBorrowRequestEmail')
    //     .call({'requestId': reqRef.id});
  }

  Future<void> approveRequest({
    required String requestId,
    required DateTime returnDate,
    required UserProfile admin,
    required List<Map<String, dynamic>> itemsUpdate,
  }) async {
    final reqRef = _db.collection('borrow_requests').doc(requestId);

    await _db.runTransaction((tx) async {
      for (var u in itemsUpdate) {
        final itemDoc = reqRef.collection('items').doc(u['itemDocId']);
        if (u['allow'] == false) {
          tx.delete(itemDoc);
        } else {
          tx.update(itemDoc, {
            'description': u['desc'],
            'serialNumber': u['serial'],
          });
        }
      }
      tx.update(reqRef, {'status': 'Approved', 'returnDate': returnDate});

      log(admin.uid, 'Approve', "Request $requestId approved");
      // _addAudit(tx, admin.uid, 'Approve', 'Request $requestId approved');
    });

    final remain = await reqRef.collection('items').count().get();
    if (remain.count == 0) {
      await reqRef.update({'status': 'Returned'});
    }
  }


  Future<void> returnEquipment(String requestId, UserProfile user) async {
    final reqRef = _db.collection('borrow_requests').doc(requestId);
    await reqRef.update({'status': 'Returned'});
    // await _db.collection('audit_logs').add({
    //   'userID': user.uid,
    //   'action': 'Return',
    //   'details': 'Request $requestId returned',
    //   'timestamp': FieldValue.serverTimestamp(),
    // });

    log(user.uid, 'Return', "Request $requestId returned");
  }


  Future<void> log(String uid, String action, String details) async {
    final adminSnap =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final adminName = adminSnap['name'] ?? 'Unknown';

    await FirebaseFirestore.instance.collection('audit_logs').add({
      'userID'   : uid,
      'userName' : adminName,
      'action'   : action,
      'details'  : details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
