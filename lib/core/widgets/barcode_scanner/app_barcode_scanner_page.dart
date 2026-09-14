import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/barcode_scanner/barcode_scanner_overlay.dart';
import 'package:yamt/core/widgets/barcode_scanner/barcode_scanner_support.dart';

const _scannerLogName = 'AppBarcodeScannerPage';

/// Signature for handling a detected barcode.
///
/// Returns `true` if barcode was accepted, or `false` to resume scanning.
typedef AppBarcodeScanCallback = FutureOr<bool> Function(String barcode);

/// Generic, feature-independent full-screen or modal barcode scanner page.
class AppBarcodeScannerPage extends StatefulWidget {
  /// Creates an [AppBarcodeScannerPage].
  const AppBarcodeScannerPage({
    required this.title,
    required this.onBarcodeScanned,
    this.actions,
    this.hintMessage,
    this.unsupportedMessage,
    super.key,
  });

  /// The title displayed in the app bar.
  final String title;

  /// Callback executed when a valid 1D barcode is captured.
  final AppBarcodeScanCallback onBarcodeScanned;

  /// Optional actions displayed in the app bar.
  final List<Widget>? actions;

  /// Guidance text displayed below the reticle window.
  final String? hintMessage;

  /// Text displayed when camera scanning is unsupported on this platform.
  final String? unsupportedMessage;

  @override
  State<AppBarcodeScannerPage> createState() => _AppBarcodeScannerPageState();
}

class _AppBarcodeScannerPageState extends State<AppBarcodeScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.itf14,
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
    detectionTimeoutMs: 1000,
  );

  bool _isLocked = false;
  bool _isTorchOn = false;
  DateTime? _lastScannedAt;
  String? _lastScannedBarcode;

  @override
  void dispose() {
    unawaited(_scannerController.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isMobileBarcodeScanSupported()) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: widget.actions,
        ),
        body: Center(
          child: Padding(
            padding: AppInsets.page,
            child: Text(
              widget.unsupportedMessage ??
                  'Barcode-Scannen wird auf dieser Plattform nicht '
                  'unterstützt.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: widget.actions,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          BarcodeScannerOverlay(
            isLocked: _isLocked,
            isTorchOn: _isTorchOn,
            onToggleTorch: _toggleTorch,
            hintMessage: widget.hintMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      if (mounted) {
        setState(() {
          _isTorchOn = !_isTorchOn;
        });
      }
    } on Object catch (error, stackTrace) {
      log(
        'Toggling scanner torch failed.',
        name: _scannerLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!mounted || _isLocked) return;

    final barcode = extractValidBarcodeFromCapture(capture);
    if (barcode == null ||
        isBarcodeScanThrottled(
          barcode: barcode,
          lastScannedBarcode: _lastScannedBarcode,
          lastScannedAt: _lastScannedAt,
        )) {
      return;
    }

    _lastScannedBarcode = barcode;
    _lastScannedAt = DateTime.now();

    setState(() {
      _isLocked = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;

    await _handleDetectedBarcode(barcode);
  }

  Future<void> _handleDetectedBarcode(String barcode) async {
    if (!mounted) return;

    try {
      await _scannerController.stop();
    } on Object {
      // Ignored if stopping fails.
    }

    final handled = await widget.onBarcodeScanned(barcode);
    if (!mounted) return;

    if (!handled) {
      setState(() {
        _isLocked = false;
      });
      try {
        await _scannerController.start();
      } on Object {
        // Ignored if starting fails.
      }
    }
  }
}
