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
