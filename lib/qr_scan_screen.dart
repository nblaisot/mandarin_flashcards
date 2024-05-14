import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScanScreen extends StatefulWidget {
  final Function(String) onUrlReceived;

  QRScanScreen({required this.onUrlReceived});

  @override
  State<StatefulWidget> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
      ),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      controller.pauseCamera(); // Pause the camera after a successful scan
      if (scanData.code != null) {
        widget.onUrlReceived(scanData.code!); // Pass the scanned URL to the callback
        Navigator.of(context).pop(); // Optionally close the scanner screen after scanning
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose(); // Dispose of the controller when the widget is disposed
    super.dispose();
  }
}
