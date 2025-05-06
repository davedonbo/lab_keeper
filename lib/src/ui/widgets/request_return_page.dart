import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/borrow_request.dart';
import '../../services/auth_service.dart';
import '../../services/borrow_service.dart';

class ReturnReviewPage extends StatefulWidget {
  const ReturnReviewPage({super.key, required this.request});
  final BorrowRequest request;

  @override
  State<ReturnReviewPage> createState() => _ReturnReviewPageState();
}

class _ReturnReviewPageState extends State<ReturnReviewPage> {
  final _selected = <String, bool>{}; // itemDocID → newly checked
  bool _busy = false;

  CollectionReference<Map<String, dynamic>> get _itemsRef =>
      FirebaseFirestore.instance
          .collection('borrow_requests')
          .doc(widget.request.id)
          .collection('items');

  DateTime get _today => DateTime.now();

  Future<void> _markReturned(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    final newlyChecked =
        _selected.values.where((v) => v == true).length; // new ticks only
    if (newlyChecked == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select items that were returned')),
      );
      return;
    }

    setState(() => _busy = true);
    final batch = FirebaseFirestore.instance.batch();
    final ts = Timestamp.fromDate(_today);

    for (final d in docs) {
      if (_selected[d.id] == true) {
        batch.update(d.reference, {
          'returned': true,
          'returnedDate': ts,
        });
      }
    }

    final allNowReturned = docs.every((d) {
      final data = d.data();
      final already = (data['returned'] ?? false) as bool;
      final newly = _selected[d.id] == true;
      return already || newly;
    });

    if (allNowReturned) {
      batch.update(
        FirebaseFirestore.instance
            .collection('borrow_requests')
            .doc(widget.request.id),
        {
          'status': 'Returned',
          'actualReturnDate': ts,
        },
      );

      final admin = await AuthService.instance.currentUserProfile();
      BorrowService.instance.log(admin!.uid, 'Return', "Request ${widget.request.id.substring(0, 6).toUpperCase()} returned");
    }



    await batch.commit();
    if (mounted) Navigator.pop(context);
  }

  /*──────────────── card builder ────────────────*/
  Widget _card(QueryDocumentSnapshot<Map<String, dynamic>> snap) {
    final m = snap.data();
    final id = snap.id;
    final already = (m['returned'] ?? false) as bool;

    final qty = m['quantity'] ?? m['qty'] ?? 0;
    final desc = m['description'] ?? '';
    final serial = m['serialNumber'] ?? '—';
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
                CheckboxListTile(
                  value: already || (_selected[id] ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(name),
                  subtitle: Text('Qty: $qty'),
                  onChanged: already
                      ? null
                      : (v) => setState(() => _selected[id] = v ?? false),
                ),
                if (desc.isNotEmpty) Text('Desc: $desc'),
                const SizedBox(height: 4),
                Text('Serial: $serial'),
                if (imgUrl != null && imgUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: InteractiveViewer(
                          child: Image.network(imgUrl, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(imgUrl,
                          width: 90, height: 90, fit: BoxFit.cover),
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

  /*──────────────── UI ───────────────────────────*/
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title:
      Text('Request ${widget.request.id.substring(0, 6).toUpperCase()}'),
      actions: [IconButton(
        icon: Icon(Icons.call),
        onPressed: () async {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.request.userID)
              .get();
          final phone = userDoc.data()?['phone'] as String?;
          if (phone != null) launchUrl(Uri.parse('tel:$phone'));
        },
      )
      ],
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _itemsRef.snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
          children: docs.map(_card).toList(),
        );
      },
    ),
    bottomNavigationBar: Material(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event_available),
              title: Text(
                  'Returned on: ${_today.day}/${_today.month}/${_today.year}'),
              trailing: Text(
                  '${_selected.values.where((v) => v).length} selected'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _busy
                  ? null
                  : () async {
                final docs =
                await _itemsRef.get().then((s) => s.docs);
                _markReturned(docs);
              },
              child: _busy
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text('Mark returned'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// minimal scanner stub (unchanged from earlier)
class _BarcodeScanPage extends StatefulWidget {
  const _BarcodeScanPage();
  @override
  State<_BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<_BarcodeScanPage> {
  final _controller = MobileScannerController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scan serial')
    ),
    body: MobileScanner(
      controller: _controller,
      onDetect: (c) async {
        if (c.barcodes.isEmpty) return;
        final code = c.barcodes.first.rawValue ?? '';
        await _controller.stop();
        if (context.mounted) Navigator.pop(context, code);
      },
    ),
  );
}
