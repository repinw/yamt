import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/domain/receipt_input_models.dart';

part 'receipt_input_repository.g.dart';

const List<String> _allowedReceiptExtensions = <String>[
  'jpg',
  'jpeg',
  'png',
  'webp',
  'heic',
  'heif',
  'pdf',
];

const String _defaultMimeType = 'application/octet-stream';
const String _fallbackCameraFileName = 'camera-image.jpg';
const String _fallbackUploadFileName = 'receipt-upload';
const int _mimeHeaderLength = 32;

@riverpod
ReceiptInputRepository receiptInputRepository(Ref ref) {
  return DeviceReceiptInputRepository();
}

/// Abstraction for receipt input sources used by the controller layer.
abstract interface class ReceiptInputRepository {
  Future<ReceiptInputResult> pickFromCamera();

  Future<ReceiptInputResult> pickFromFile();
}

/// Plugin-backed implementation using `image_picker` and `file_picker`.
///
/// Note: This class calls platform channels directly. We cover its decision
/// flow through controller tests with a fake [ReceiptInputRepository], while
/// end-to-end plugin behavior is validated in integration/manual testing.
class DeviceReceiptInputRepository implements ReceiptInputRepository {
  DeviceReceiptInputRepository({
    ImagePicker? imagePicker,
    FilePicker? filePicker,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       _filePicker = filePicker ?? FilePicker.platform;

  final ImagePicker _imagePicker;
  final FilePicker _filePicker;

  @override
  Future<ReceiptInputResult> pickFromCamera() {
    return _runPick(
      failureCode: ReceiptInputErrorCodes.cameraPickFailed,
      loadSelection: _pickCameraSelection,
    );
  }

  @override
  Future<ReceiptInputResult> pickFromFile() {
    return _runPick(
      failureCode: ReceiptInputErrorCodes.filePickFailed,
      loadSelection: _pickFileSelection,
    );
  }

  Future<ReceiptInputResult> _runPick({
    required String failureCode,
    required Future<ReceiptInputSelection?> Function() loadSelection,
  }) async {
    try {
      final selection = await loadSelection();
      if (selection == null) {
        return const ReceiptInputResult.canceled();
      }

      return ReceiptInputResult.selected(selection: selection);
    } catch (_) {
      return ReceiptInputResult.failed(errorCode: failureCode);
    }
  }

  Future<ReceiptInputSelection?> _pickCameraSelection() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) {
      return null;
    }

    final fileName = _resolvedFileName(
      primaryName: pickedFile.name,
      fallbackPath: pickedFile.path,
      fallbackName: _fallbackCameraFileName,
    );
    final bytes = await pickedFile.readAsBytes();

    return ReceiptInputSelection(
      source: ReceiptInputSource.camera,
      name: fileName,
      mimeType: _detectMimeType(fileName: fileName, bytes: bytes),
      bytes: bytes,
    );
  }

  Future<ReceiptInputSelection?> _pickFileSelection() async {
    final result = await _filePicker.pickFiles(
      allowMultiple: false,
      withData: _shouldPreloadFileBytes,
      type: FileType.custom,
      allowedExtensions: _allowedReceiptExtensions,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;
    final bytes = await _resolveFileBytes(file);
    if (bytes == null) {
      return null;
    }

    final fileName = _resolvedFileName(
      primaryName: file.name,
      fallbackPath: file.path,
      fallbackName: _fallbackUploadFileName,
    );

    return ReceiptInputSelection(
      source: ReceiptInputSource.file,
      name: fileName,
      mimeType: _detectMimeType(fileName: fileName, bytes: bytes),
      bytes: bytes,
    );
  }

  bool get _shouldPreloadFileBytes => kIsWeb;

  Future<Uint8List?> _resolveFileBytes(PlatformFile file) async {
    final inMemoryBytes = file.bytes;
    if (inMemoryBytes != null) {
      return inMemoryBytes;
    }

    final path = file.path;
    if (path == null || path.isEmpty) {
      return null;
    }

    return XFile(path).readAsBytes();
  }
}

String _resolvedFileName({
  required String primaryName,
  required String fallbackName,
  String? fallbackPath,
}) {
  if (primaryName.isNotEmpty) {
    return primaryName;
  }

  final fromPath = fallbackPath == null ? '' : _fileNameFromPath(fallbackPath);
  if (fromPath.isNotEmpty) {
    return fromPath;
  }

  return fallbackName;
}

String _fileNameFromPath(String path) {
  final normalizedPath = path.replaceAll('\\', '/');
  final separatorIndex = normalizedPath.lastIndexOf('/');
  if (separatorIndex == -1) {
    return normalizedPath;
  }
  return normalizedPath.substring(separatorIndex + 1);
}

String _detectMimeType({required String fileName, required Uint8List bytes}) {
  final headerLength = bytes.length < _mimeHeaderLength
      ? bytes.length
      : _mimeHeaderLength;
  final headerBytes = bytes.sublist(0, headerLength);

  final mimeType = lookupMimeType(fileName, headerBytes: headerBytes);
  if (mimeType == null || mimeType.isEmpty) {
    return _defaultMimeType;
  }

  return mimeType;
}
