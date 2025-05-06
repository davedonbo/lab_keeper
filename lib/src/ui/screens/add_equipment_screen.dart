import 'package:flutter/material.dart';
import '../../services/equipment_service.dart';
import '../../services/auth_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/primary_text_field.dart';

class AddEquipmentScreen extends StatefulWidget {
  const AddEquipmentScreen({super.key});
  @override State<AddEquipmentScreen> createState() => _AddEquipmentState();
}

class _AddEquipmentState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final admin = await AuthService.instance.currentUserProfile();
    await EquipmentService.instance
        .addEquipment(_nameCtrl.text.trim(), admin!);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Item added')));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add Equipment')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            PrimaryTextField(
              controller: _nameCtrl,
              label: 'Equipment Name',
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Save',
              loading: _loading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    ),
  );
}
