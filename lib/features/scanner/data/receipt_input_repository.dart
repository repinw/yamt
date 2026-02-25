import 'dart:developer' show log;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

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
ImagePicker imagePicker(Ref ref) {
  return ImagePicker();
}

@riverpod
FilePicker filePicker(Ref ref) {
  return FilePicker.platform;
}

@riverpod
ReceiptInputRepository receiptInputRepository(Ref ref) {
  return DeviceReceiptInputRepository(
    imagePicker: ref.watch(imagePickerProvider),
    filePicker: ref.watch(filePickerProvider),
  );
}

/// Abstraction for receipt input sources used by the controller layer.
abstract interface class ReceiptInputRepository {
  Future<ReceiptInputResult> pickFromCamera();

  Future<ReceiptInputResult> pickFromFile();

  Future<ReceiptInputBatchResult> pickFromFiles();
}

/// Plugin-backed implementation using `image_picker` and `file_picker`.
///
/// Note: This class calls platform channels directly. We cover its decision
/// flow through controller tests with a fake [ReceiptInputRepository], while
/// end-to-end plugin behavior is validated in integration/manual testing.
class DeviceReceiptInputRepository implements ReceiptInputRepository {
  DeviceReceiptInputRepository({
    required ImagePicker imagePicker,
    required FilePicker filePicker,
  }) : _imagePicker = imagePicker,
       _filePicker = filePicker;

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

  @override
  Future<ReceiptInputBatchResult> pickFromFiles() {
    return _runBatchPick(
      failureCode: ReceiptInputErrorCodes.filePickFailed,
      loadSelections: _pickFileSelections,
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
    } catch (error, stackTrace) {
      log(
        'Receipt input repository pick failed (code: $failureCode)',
        name: 'DeviceReceiptInputRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return ReceiptInputResult.failed(errorCode: failureCode);
    }
  }

  Future<ReceiptInputBatchResult> _runBatchPick({
    required String failureCode,
    required Future<List<ReceiptInputSelection>?> Function() loadSelections,
  }) async {
    try {
      final selections = await loadSelections();
      if (selections == null || selections.isEmpty) {
        return const ReceiptInputBatchResult.canceled();
      }

      return ReceiptInputBatchResult.selected(selections: selections);
    } catch (error, stackTrace) {
      log(
        'Receipt input batch pick failed (code: $failureCode)',
        name: 'DeviceReceiptInputRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return ReceiptInputBatchResult.failed(errorCode: failureCode);
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
    final result = await _pickFiles(allowMultiple: false);
    if (result == null || result.files.isEmpty) {
      return null;
    }

    return _selectionFromFile(result.files.first);
  }

  Future<List<ReceiptInputSelection>?> _pickFileSelections() async {
    final result = await _pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) {
      return null;
    }

    final selections = <ReceiptInputSelection>[];
    for (final file in result.files) {
      final selection = await _selectionFromFile(file);
      if (selection == null) {
        throw StateError('Could not load selected file bytes');
      }
      selections.add(selection);
    }
    return selections;
  }

  Future<FilePickerResult?> _pickFiles({required bool allowMultiple}) {
    return _filePicker.pickFiles(
      allowMultiple: allowMultiple,
      withData: _shouldPreloadFileBytes,
      type: FileType.custom,
      allowedExtensions: _allowedReceiptExtensions,
    );
  }

  Future<ReceiptInputSelection?> _selectionFromFile(PlatformFile file) async {
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
  final normalizedPrimaryName = _fileNameFromPath(primaryName);
  if (normalizedPrimaryName.isNotEmpty) {
    return normalizedPrimaryName;
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
