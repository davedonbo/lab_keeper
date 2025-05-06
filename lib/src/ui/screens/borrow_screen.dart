import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/equipment.dart';
import '../../services/equipment_service.dart';
import '../../services/auth_service.dart';
import '../../services/borrow_service.dart';
import '../widgets/primary_button.dart';

class BorrowScreen extends StatefulWidget {
  const BorrowScreen({super.key});
  @override State<BorrowScreen> createState() => _BorrowScreenState();
}

class _SelectedItem {
  final qtyCtrl = TextEditingController(text: '1');
  final descCtrl = TextEditingController();
  void dispose() {
    qtyCtrl.dispose();
    descCtrl.dispose();
  }
}

class _BorrowScreenState extends State<BorrowScreen> {
  final Map<String, _SelectedItem> selected = {};
  final _formKey = GlobalKey<FormState>();
  DateTime? collectionDate;
  bool _loading = false;

  int get totalSelected => selected.length;

  Future<void> _submit() async {
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select an item.')));
      return;
    }
    if (collectionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pick a collection date.')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final user = await AuthService.instance.currentUserProfile();
    await BorrowService.instance.requestEquipment(
      student: user!,
      collectionDateTime: collectionDate!,
      items: selected.entries
          .map((e) => {
        'equipmentId': e.key,
        'qty': int.parse(e.value.qtyCtrl.text),
        'desc': e.value.descCtrl.text.trim(),
      })
          .toList(),
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Request sent!')));
  }

  @override
  void dispose() {
    for (final i in selected.values) i.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borrow Equipment')),
      body: StreamBuilder<QuerySnapshot>(
        stream: EquipmentService.instance.streamAll(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!.docs
              .map((d) =>
              Equipment.fromJson(d.id, d.data()! as Map<String, dynamic>))
              .toList();

          if (items.isEmpty) {
            return const Center(child: Text('No equipment available.'));
          }

          return Form(
            key: _formKey,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final e = items[index];
                final isSel = selected.containsKey(e.id);

                return Card(
                  key: ValueKey(e.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: isSel,
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  selected[e.id] = _SelectedItem();
                                } else {
                                  selected[e.id]?.dispose();
                                  selected.remove(e.id);
                                }
                              }),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        if (isSel) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: selected[e.id]!.qtyCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Qty',
                                    border: OutlineInputBorder(),
                                  ),
                                  // <-- removed onChanged so we don't rebuild on every keystroke
                                  validator: (v) {
                                    final n = int.tryParse(v ?? '');
                                    if (n == null || n <= 0) {
                                      return 'Positive num';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: selected[e.id]!.descCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Description (optional)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );

        },
      ),
      // —— fixed action panel ——————————————————————————————
      bottomNavigationBar: Material(
        elevation: 8,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding:
          const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Collection Date'),
                subtitle: Text(collectionDate == null
                    ? 'Tap to select'
                    : '${collectionDate!.day}/${collectionDate!.month}/${collectionDate!.year}'),
                trailing:
                Text('$totalSelected item${totalSelected == 1 ? '' : 's'}'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) setState(() => collectionDate = picked);
                },
              ),
              PrimaryButton(
                label: 'Submit request',
                loading: _loading,
                onPressed: _loading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
