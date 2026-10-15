import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:yamt/core/utils/barcode_utils.dart';

/// Checks if mobile barcode scanning is supported on current platform.
bool isMobileBarcodeScanSupported() {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

/// Checks whether scanning [barcode] should be throttled based on recent scan.
bool isBarcodeScanThrottled({
  required String barcode,
  required String? lastScannedBarcode,
  required DateTime? lastScannedAt,
  Duration throttleDuration = const Duration(milliseconds: 1500),
}) {
  if (lastScannedBarcode != barcode || lastScannedAt == null) {
    return false;
  }
  return DateTime.now().difference(lastScannedAt) < throttleDuration;
}

/// A camera controller for the product barcodes the app reads. It sends a
/// held barcode again every 150 ms instead of once, so
/// [BarcodeScanConfirmation] can decide when a read counts.
MobileScannerController createBarcodeScannerController() {
  return MobileScannerController(
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
    detectionTimeoutMs: 150,
  );
}

/// Accepts a barcode only after the same value was read [requiredReads] times
/// in a row, each within [window] of the previous read, so a single misread
/// or a code that crosses the frame never counts.
class BarcodeScanConfirmation {
  /// Creates a confirmation.
  new({
    this.requiredReads = 2,
    this.window = const Duration(milliseconds: 800),
  });

  /// How many reads of the same value in a row a barcode needs.
  final int requiredReads;

  /// The longest gap between two reads of the same barcode.
  final Duration window;

  String? _candidate;
  DateTime? _lastReadAt;
  var _reads = 0;

  /// Forgets the reads so far, such as when the scanner starts again.
  void reset() {
    _candidate = null;
    _lastReadAt = null;
    _reads = 0;
  }

  /// Counts a read of [barcode] at [now]; returns whether it is confirmed.
  bool confirm(String barcode, DateTime now) {
    final lastReadAt = _lastReadAt;
    final continues =
        barcode == _candidate &&
        lastReadAt != null &&
        now.difference(lastReadAt) <= window;
    _reads = continues ? _reads + 1 : 1;
    _candidate = barcode;
    _lastReadAt = now;
    return _reads >= requiredReads;
  }
}

/// Extracts the first valid 1D barcode from [capture], ignoring 2D codes (QR,
/// DataMatrix, Aztec) and invalid checksums.
String? extractValidBarcodeFromCapture(BarcodeCapture capture) {
  for (final barcodeItem in capture.barcodes) {
    if (barcodeItem.format == BarcodeFormat.qrCode ||
        barcodeItem.format == BarcodeFormat.dataMatrix ||
        barcodeItem.format == BarcodeFormat.aztec) {
      continue;
    }

    final rawBarcode = barcodeItem.rawValue;
    if (rawBarcode == null || rawBarcode.trim().isEmpty) {
      continue;
    }

    final barcode = normalizeBarcode(rawBarcode);
    if (isValidBarcode(barcode)) {
      return barcode;
    }
  }
  return null;
}
