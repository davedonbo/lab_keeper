import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Stateful scanner page—stops camera before returning
class BarcodeScanPage extends StatefulWidget {
  const BarcodeScanPage();
  @override
  State<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
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
        await _controller.stop(); // prevent black frame
        if (context.mounted) Navigator.pop(context, code);
      },
    ),
  );
}