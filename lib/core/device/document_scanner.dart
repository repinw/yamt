import 'dart:developer' show log;

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:image_picker/image_picker.dart';

/// Takes up to [maxPages] photos with the native document scanner, which
/// finds the edges, crops, and straightens each page. Returns the paths of
/// the pages, or null when the user cancels.
///
/// When the scanner fails, for example on a device without it, a plain
/// camera photo from [fallbackPicker] stands in for it. A denied camera
/// permission throws the scanner's exception.
Future<List<String>?> scanDocumentPages({
  required int maxPages,
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
  try {
    return await CunningDocumentScanner.getPictures(
      noOfPages: maxPages,
      scannerSource: ScannerSource.camera,
      // iOS writes PNG by default; JPEG keeps the pages small.
      iosScannerOptions: IosScannerOptions(
        imageFormat: IosImageFormat.jpg,
        jpgCompressionQuality: 0.9,
      ),
    );
  } on Object catch (error, stackTrace) {
    if (error is CunningDocumentScannerException) {
      // A second tap while a scan runs: the running scan answers.
      if (error.code == 'ALREADY_ACTIVE') return null;
      // The plain camera needs the same permission.
      if (error.code == 'permission_denied') rethrow;
    }
    log(
      'The document scanner failed; falling back to the camera.',
      name: 'DocumentScanner',
      error: error,
      stackTrace: stackTrace,
    );
    final file = await (fallbackPicker ?? ImagePicker()).pickImage(
      source: ImageSource.camera,
    );
    return file == null ? null : [file.path];
  }
}
