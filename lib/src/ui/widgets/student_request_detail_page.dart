import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/borrow_request.dart';
import '../../models/borrow_status.dart';

class StudentRequestDetailPage extends StatelessWidget {
  const StudentRequestDetailPage({super.key, required this.request});
  final BorrowRequest request;

  CollectionReference<Map<String, dynamic>> get _items =>
      FirebaseFirestore.instance
          .collection('borrow_requests')
          .doc(request.id)
          .collection('items');

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title:
      Text('Request ${request.id.substring(0, 6).toUpperCase()}'),
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _items.snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No items'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) => _ItemCard(snap: docs[i]),
        );
      },
    ),
  );
}

/*──────── single item card ────────*/
class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.snap});
  final QueryDocumentSnapshot<Map<String, dynamic>> snap;

  @override
  Widget build(BuildContext context) {
    final m = snap.data();
    final qty = m['quantity'] ?? m['qty'] ?? 0;
    final desc = m['description'] ?? '';
    final serial = m['serialNumber'] ?? '—';
    final approved = (m['allow'] ?? false) as bool;
    final returned = (m['returned'] ?? false) as bool;
    final imgUrl = m['imageUrl'] as String?;

    Future<String> _resolveName() async {
      final local = m['equipmentName'] ?? m['name'];
      if (local != null) return local;
      final equipId = m['equipmentID'] ?? m['equipmentId'];
      if (equipId == null) return 'Unknown';
      final doc = await FirebaseFirestore.instance
          .collection('equipment')
          .doc(equipId)
          .get();
      return (doc.data()?['name'] as String?) ?? 'Unknown';
    }

    Widget _statusBadge() {
      if (returned) {
        return Row(
          children: const [
            Icon(Icons.assignment_turned_in, size: 18, color: Colors.blue),
            SizedBox(width: 4),
            Text('Returned', style: TextStyle(color: Colors.blue)),
          ],
        );
      } else if (approved) {
        return Row(
          children: const [
            Icon(Icons.check_circle_outline,
                size: 18, color: Colors.green),
            SizedBox(width: 4),
            Text('Approved', style: TextStyle(color: Colors.green)),
          ],
        );
      } else {
        return Row(
          children: const [
            Icon(Icons.pending_outlined,
                size: 18, color: Colors.orange),
            SizedBox(width: 4),
            Text('Pending', style: TextStyle(color: Colors.orange)),
          ],
        );
      }
    }

    return FutureBuilder<String>(
      future: _resolveName(),
      builder: (_, s) {
        final name = s.data ?? '…';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style:
                    Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Qty: $qty'),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Desc: $desc'),
                ],
                const SizedBox(height: 4),
                Text('Serial: $serial'),
                const SizedBox(height: 8),
                _statusBadge(),
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
  }
}
