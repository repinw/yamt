
/// Contract for extracting raw text from receipt files locally on-device.
abstract interface class ReceiptTextExtractor {
  /// Extracts raw text from the specified receipt [filePaths].
  ///
  /// For single receipts, pass a single file path. For multi-photo
  /// receipts (e.g. overlapping slices of a long receipt), pass all
  /// file paths in top-to-bottom order.
  ///
  /// Returns the extracted raw text.
  Future<String> extractText(List<String> filePaths);

  /// Releases any underlying native or memory resources held by this extractor.
  Future<void> dispose();
}
