final _barcodeCharacters = RegExp('[^0-9]');

/// Removes non-digit characters from a scanned barcode string.
String normalizeBarcode(String rawBarcode) {
  return rawBarcode.trim().replaceAll(_barcodeCharacters, '');
}

/// Accepts common EAN/GTIN barcode lengths used in the app.
bool isSupportedBarcode(String barcode) {
  if (barcode.isEmpty) {
    return false;
  }
  if (barcode.length < 8 || barcode.length > 14) {
    return false;
  }
  return true;
}
