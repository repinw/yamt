final _barcodeSeparators = RegExp(r'[\s\-_]');
final _invalidBarcodeChars = RegExp('[a-zA-Z:/?#]');

/// Removes separators (spaces, hyphens) from a scanned barcode string.
///
/// If the input contains alphabetic characters or URL syntax (e.g. from a QR
/// code), this returns an empty string to reject non-barcode content.
String normalizeBarcode(String rawBarcode) {
  final trimmed = rawBarcode.trim();
  if (trimmed.isEmpty || _invalidBarcodeChars.hasMatch(trimmed)) {
    return '';
  }
  return trimmed.replaceAll(_barcodeSeparators, '');
}

/// Accepts common numeric EAN/GTIN barcode lengths used in the app.
bool isSupportedBarcode(String barcode) {
  if (barcode.isEmpty) {
    return false;
  }
  if (barcode.length < 8 || barcode.length > 14) {
    return false;
  }
  return RegExp(r'^\d+$').hasMatch(barcode);
}

/// Computes and verifies the official GS1 Modulo-10 check digit.
///
/// Applicable to standard GTIN lengths:
/// - 8 digits (EAN-8)
/// - 12 digits (UPC-A / GTIN-12)
/// - 13 digits (EAN-13 / GTIN-13)
/// - 14 digits (ITF-14 / GTIN-14)
bool isValidGtinChecksum(String digits) {
  if (!RegExp(r'^\d+$').hasMatch(digits)) {
    return false;
  }
  if (digits.length != 8 &&
      digits.length != 12 &&
      digits.length != 13 &&
      digits.length != 14) {
    return false;
  }

  var sum = 0;
  var weight = 3;
  for (var i = digits.length - 2; i >= 0; i--) {
    final digit = digits.codeUnitAt(i) - 48;
    sum += digit * weight;
    weight = weight == 3 ? 1 : 3;
  }

  final expectedCheckDigit = (10 - (sum % 10)) % 10;
  final actualCheckDigit = digits.codeUnitAt(digits.length - 1) - 48;
  return expectedCheckDigit == actualCheckDigit;
}

/// Validates whether [barcode] is a well-formed barcode.
///
/// Verifies length and digits via [isSupportedBarcode], and for standard
/// GTIN lengths (8, 12, 13, 14) verifies the GS1 Modulo-10 checksum.
bool isValidBarcode(String barcode, {bool enforceChecksum = true}) {
  if (!isSupportedBarcode(barcode)) {
    return false;
  }
  if (!enforceChecksum) {
    return true;
  }
  if (barcode.length == 8 ||
      barcode.length == 12 ||
      barcode.length == 13 ||
      barcode.length == 14) {
    return isValidGtinChecksum(barcode);
  }
  return true;
}
