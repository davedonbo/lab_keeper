import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/borrow_request.dart';
import '../../models/borrow_status.dart';
import '../../services/auth_service.dart';
import '../../services/borrow_service.dart';

class RequestReviewPage extends StatefulWidget {
  const RequestReviewPage({super.key, required this.request});
  final BorrowRequest request;

  @override
  State<RequestReviewPage> createState() => _RequestReviewPageState();
}

class _RequestReviewPageState extends State<RequestReviewPage> {
  final _selected = <String, bool>{};
  final _serials  = <String, String>{};
  final _photo    = <String, File?>{};
  DateTime? _returnDate;
  bool _busy = false;

  CollectionReference<Map<String, dynamic>> get _itemsRef =>
      FirebaseFirestore.instance
          .collection('borrow_requests')
          .doc(widget.request.id)
          .collection('items');

  int get _countSelected => _selected.values.where((v) => v).length;

  // resolve equipment name (local or fetch)
  Future<String> _resolveName(Map<String, dynamic> m) async {
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

  // pick camera/gallery (one image per item)
  Future<void> _pickImage(String itemId) async {
    if (_photo[itemId] != null) {
      setState(() => _photo[itemId] = null);
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
    if (source == null) return;
    final picked =
    await ImagePicker().pickImage(source: source, imageQuality: 70,maxWidth: 800,maxHeight: 600);
    if (picked != null) {
      setState(() => _photo[itemId] = File(picked.path));
    }
  }

  // scan barcode for serial
  Future<void> _scanSerial(String itemId) async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _BarcodeScanPage()),
    );
    if (code != null && code.isNotEmpty) {
      setState(() => _serials[itemId] = code);
    }
  }

  // upload image and return URL
  Future<String> _uploadImage(String id, File f) async {
    final ref = FirebaseStorage.instance
        .ref('borrow_items/${widget.request.id}/$id.jpg');
    await ref.putFile(f);
    return ref.getDownloadURL();
  }

  // show slim cancelable dialog & verify proximity ≤30 m
  Future<bool> _confirmProximity() async {
    var cancelled = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text('Checking proximity'),
          content: const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          ),
          actions: [
            TextButton(
              onPressed: () {
                cancelled = true;
                Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            )
          ],
        ),
      ),
    );

    try {
      // admin location
      final pos = await Geolocator.getCurrentPosition();
      if (cancelled) return false;

      // student presence
      final pres = await FirebaseFirestore.instance
          .collection('presence')
          .doc(widget.request.userID)
          .get();
      if (cancelled) {
        Navigator.pop(context);
        return false;
      }
      if (!pres.exists || pres.data() == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not broadcasting')),
        );
        return false;
      }
      final data = pres.data()!;
      final lat = (data['lat'] as num).toDouble();
      final lng = (data['lng'] as num).toDouble();

      final dist = Geolocator.distanceBetween(
        pos.latitude, pos.longitude,
        lat, lng,
      );
      Navigator.pop(context);

      if (dist <= 30) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proximity validated')),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              'Too far: ${dist.toStringAsFixed(1)} m')),
        );
        return false;
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      return false;
    }
  }

  // approval batch logic
  Future<void> _approve(List<QueryDocumentSnapshot> docs) async {
    // basic validation
    if (_returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick return date')),
      );
      return;
    }
    if (_countSelected == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one item')),
      );
      return;
    }
    for (final d in docs.where((d) => _selected[d.id] == true)) {
      if ((_serials[d.id]?.isEmpty ?? true) || _photo[d.id] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(
              'Serial & image required for each selected')),
        );
        return;
      }
    }

    setState(() => _busy = true);
    final batch = FirebaseFirestore.instance.batch();
    for (final d in docs) {
      if (_selected[d.id] == true) {
        final url = await _uploadImage(d.id, _photo[d.id]!);
        batch.update(d.reference, {
          'serialNumber': _serials[d.id],
          'imageUrl': url,
          'allow':true
        });
      } else {
        batch.delete(d.reference);
      }
    }
    batch.update(
      FirebaseFirestore.instance
          .collection('borrow_requests')
          .doc(widget.request.id),
      {
        'status': 'Approved',
        'returnDate': Timestamp.fromDate(_returnDate!),
      },
    );
    await batch.commit();

    final admin = await AuthService.instance.currentUserProfile();
    BorrowService.instance.log(admin!.uid, 'Approve', "Request ${widget.request.id.substring(0, 6).toUpperCase()} approved");

    if (mounted) Navigator.pop(context);
  }

  Future<void> _markReturned() async {
    setState(() => _busy = true);
    await FirebaseFirestore.instance
        .collection('borrow_requests')
        .doc(widget.request.id)
        .update({'status': 'Returned'});

    final admin = await AuthService.instance.currentUserProfile();
    BorrowService.instance.log(admin!.uid, 'Return', "Request ${widget.request.id.substring(0, 6).toUpperCase()} returned");
    if (mounted) Navigator.pop(context);
  }

  Widget _itemTile(QueryDocumentSnapshot d) {
    final m = d.data()! as Map<String, dynamic>;
    final id = d.id;
    final qty = m['quantity'] ?? 0;
    final desc = m['description'] ?? '';
    final checked = _selected[id] == true;

    return FutureBuilder<String>(
      future: _resolveName(m),
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
                  value: checked,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(name),
                  subtitle: Text('Qty: $qty'),
                  onChanged: (v) =>
                      setState(() => _selected[id] = v ?? false),
                ),
                if (checked) ...[
                  if (desc.isNotEmpty) Text('Desc: $desc'),
                  const SizedBox(height: 8),
                  TextField(
                    controller:
                    TextEditingController(text: _serials[id] ?? ''),
                    decoration: InputDecoration(
                      labelText: 'Serial number',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: () => _scanSerial(id),
                      ),
                    ),
                    onChanged: (v) => _serials[id] = v.trim(),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickImage(id),
                    child: _photo[id] == null
                        ? Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.camera_alt),
                    )
                        : Image.file(_photo[id]!,
                        width: 80, height: 80, fit: BoxFit.cover),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

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
    body: StreamBuilder<QuerySnapshot>(
      stream: _itemsRef.snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
          children: docs.map(_itemTile).toList(),
        );
      },
    ),
    bottomNavigationBar: Material(
      elevation: 8,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event),
              title: Text(_returnDate == null
                  ? 'Return date'
                  : '${_returnDate!.day}/${_returnDate!.month}/${_returnDate!.year}'),
              trailing: Text('$_countSelected selected'),
              onTap: () async {
                final pick = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate:
                  DateTime.now().add(const Duration(days: 180)),
                );
                if (pick != null) setState(() => _returnDate = pick);
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              onPressed: _busy
                  ? null
                  : () async {
                final docs =
                    (await _itemsRef.get()).docs;
                final ok = await _confirmProximity();
                if (ok) await _approve(docs);
              },
              child: _busy
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(
                      Colors.white),
                ),
              )
                  : const Text('Approve'),
            ),
            if (widget.request.status ==
                BorrowStatus.approved) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.assignment_return),
                label: const Text('Mark returned'),
                onPressed: _busy ? null : _markReturned,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Simple barcode scanner page
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
    appBar: AppBar(title: const Text('Scan serial')),
    body: MobileScanner(
      controller: _controller,
      onDetect: (capture) async {
        if (capture.barcodes.isEmpty) return;
        final code = capture.barcodes.first.rawValue ?? '';
        await _controller.stop();
        if (mounted) Navigator.pop(context, code);
      },
    ),
  );
}
