import 'dart:developer' show log;

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

// The plugin's own getPictures turns an empty result into null, the same as
// a cancel; its channel keeps the two apart (#764).
const _scannerChannel = MethodChannel('cunning_document_scanner');

/// Takes up to [maxPages] photos with the native document scanner, which
/// finds the edges, crops, and straightens each page. Returns the paths of
/// the pages, or null when the user cancels.
///
/// A scan that ends without a cancel but also without a page takes the
/// camera photo, so a lost scan never looks like a cancel.
///
/// When the scanner fails, for example on a device without it, a plain
/// camera photo from [fallbackPicker] stands in for it. A denied camera
/// permission throws the scanner's exception.
///
/// With [allowGallery], the scanner also offers a photo from the gallery to
/// crop: a button in the Android scanner, a camera or gallery choice first on
/// iOS. The plugin ships the iOS labels.
Future<List<String>?> scanDocumentPages({
  required int maxPages,
  bool allowGallery = false,
  ImagePicker? fallbackPicker,
}) async {
  // The scanner keeps its pages in app storage, not the cache. The pages of
  // the last scan are read by the time the next scan starts.
  try {
    await CunningDocumentScanner.cleanCache();
  } on Object catch (error, stackTrace) {
    log(
      'Cleaning the old scans failed.',
      name: 'DocumentScanner',
      error: error,
      stackTrace: stackTrace,
    );
  }
  final List<String>? pages;
  try {
    pages = await _getPictures(maxPages, allowGallery: allowGallery);
  } on Object catch (error, stackTrace) {
    if (error is CunningDocumentScannerException) {
      // A second tap while a scan runs: the running scan answers.
      if (error.code == 'ALREADY_ACTIVE') return null;
      // The plain camera needs the same permission.
      if (error.code == 'permission_denied') rethrow;
    }
    // Release builds drop developer.log; debugPrint still reaches logcat.
    debugPrint(
      '[DocumentScanner] The scanner failed: $error; using the camera.',
    );
    log(
      'The document scanner failed; falling back to the camera.',
      name: 'DocumentScanner',
      error: error,
      stackTrace: stackTrace,
    );
    return await _pickCameraPhoto(fallbackPicker);
  }
  if (pages == null) {
    // Also the plugin's answer to a scan that ended without RESULT_OK.
    debugPrint('[DocumentScanner] The scan was canceled.');
    return null;
  }
  if (pages.isNotEmpty) return pages;
  debugPrint('[DocumentScanner] The scan returned no page; using the camera.');
  return await _pickCameraPhoto(fallbackPicker);
}

/// The plugin's getPictures without its null for an empty result.
Future<List<String>?> _getPictures(
  int maxPages, {
  required bool allowGallery,
}) async {
  try {
    final pages = await _scannerChannel.invokeMethod<List<Object?>>(
      'getPictures',
      {
        'noOfPages': maxPages,
        'isGalleryImportAllowed': allowGallery,
        'scannerSource':
            (allowGallery
                    ? ScannerSource.cameraAndGallery
                    : ScannerSource.camera)
                .methodChannelValue,
        'androidScannerMode': AndroidScannerMode.full.methodChannelValue,
        'asPdf': false,
        // iOS writes PNG by default; JPEG keeps the pages small.
        'iosScannerOptions': IosScannerOptions(
          imageFormat: IosImageFormat.jpg,
          jpgCompressionQuality: 0.9,
        ).toMap(),
      },
    );
    return pages == null ? null : [for (final page in pages) page! as String];
  } on PlatformException catch (error) {
    throw CunningDocumentScannerException(
      error.message ?? 'The document scan failed',
      code: error.code,
    );
  }
}

Future<List<String>?> _pickCameraPhoto(ImagePicker? fallbackPicker) async {
  final file = await (fallbackPicker ?? ImagePicker()).pickImage(
    source: ImageSource.camera,
  );
  return file == null ? null : [file.path];
}
