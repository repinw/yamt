final _barcodeCharacters = RegExp(r'[^0-9]');

String normalizeBarcode(String rawBarcode) {
  return rawBarcode.trim().replaceAll(_barcodeCharacters, '');
}

bool isSupportedBarcode(String barcode) {
  if (barcode.isEmpty) {
    return false;
  }
  if (barcode.length < 8 || barcode.length > 14) {
    return false;
  }
  return true;
}
