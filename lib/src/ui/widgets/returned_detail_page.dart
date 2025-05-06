import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/borrow_request.dart';

class ReturnedDetailPage extends StatelessWidget {
  const ReturnedDetailPage({super.key, required this.request});
  final BorrowRequest request;

  CollectionReference<Map<String, dynamic>> get _itemsRef =>
      FirebaseFirestore.instance
          .collection('borrow_requests')
          .doc(request.id)
          .collection('items');

  /// First try the local field; if missing, fetch from /equipment/{id}
  Future<String> _resolveName(Map<String, dynamic> m) async {
    final local = m['equipmentName'] ?? m['name'];
    if (local is String && local.isNotEmpty) return local;
    final equipId = m['equipmentID'] ?? m['equipmentId'];
    if (equipId is! String) return 'Unknown';
    final doc = await FirebaseFirestore.instance
        .collection('equipment')
        .doc(equipId)
        .get();
    final data = doc.data();
    return (data != null && data['name'] is String)
        ? data['name'] as String
        : 'Unknown';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title:
      Text('Request ${request.id.substring(0, 6).toUpperCase()}'),
      actions: [
        IconButton(
          icon: const Icon(Icons.call),
          onPressed: () async {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(request.userID)
                .get();
            final phone = userDoc.data()?['phone'] as String?;
            if (phone != null) launchUrl(Uri.parse('tel:$phone'));
          },
        ),
      ],
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _itemsRef.snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final m = docs[i].data();
            final qty = m['quantity'] ?? m['qty'] ?? 0;
            final serial = m['serialNumber'] ?? '—';
            final desc = m['description'] ?? '';
            final imgUrl = m['imageUrl'] as String?;

            return FutureBuilder<String>(
              future: _resolveName(m),
              builder: (context, nameSnap) {
                final name = nameSnap.data ?? '…';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium),
                        const SizedBox(height: 4),
                        Text('Qty: $qty'),
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Desc: $desc'),
                        ],
                        const SizedBox(height: 4),
                        Text('Serial: $serial'),
                        if (imgUrl != null && imgUrl.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                child: InteractiveViewer(
                                  child: Image.network(imgUrl,
                                      fit: BoxFit.contain),
                                ),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(imgUrl,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ),
  );
}
