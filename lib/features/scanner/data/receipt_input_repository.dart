import 'dart:developer' show log;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/scanner/data/receipt_input_selection_loader.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

part 'receipt_input_repository.g.dart';

const int _maxBatchSelectionCount = 20;

/// Image picker.
@riverpod
ImagePicker imagePicker(Ref ref) {
  return ImagePicker();
}

/// File picker.
@riverpod
FilePicker filePicker(Ref ref) {
  return FilePicker.platform;
}

/// Receipt input repository.
@riverpod
ReceiptInputRepository receiptInputRepository(Ref ref) {
  return DeviceReceiptInputRepository(
    imagePicker: ref.watch(imagePickerProvider),
    filePicker: ref.watch(filePickerProvider),
  );
}

/// Abstraction for receipt input sources used by the controller layer.
abstract interface class ReceiptInputRepository {
  /// Pick from camera.
  Future<ReceiptInputResult> pickFromCamera();

  /// Pick from file.
  Future<ReceiptInputResult> pickFromFile();

  /// Pick from files.
  Future<ReceiptInputBatchResult> pickFromFiles();
}

/// Plugin-backed implementation using `image_picker` and `file_picker`.
///
/// Note: This class calls platform channels directly. We cover its decision
/// flow through controller tests with a fake [ReceiptInputRepository], while
/// end-to-end plugin behavior is validated in integration/manual testing.
class DeviceReceiptInputRepository implements ReceiptInputRepository {
  /// Creates an instance.
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

    return ReceiptInputSelectionLoader.loadFromXFile(
      pickedFile,
      source: ReceiptInputSource.camera,
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
    if (result.files.length > _maxBatchSelectionCount) {
      throw const _ReceiptInputBatchException(
        'Too many files selected for receipt batch processing.',
      );
    }

    final selections = <ReceiptInputSelection>[];
    final skippedFileNames = <String>[];
    final skippedLargeFileNames = <String>[];
    for (final file in result.files) {
      if (ReceiptInputSelectionLoader.isFileTooLarge(file)) {
        skippedLargeFileNames.add(file.name);
        continue;
      }
      final selection =
          ReceiptInputSelectionLoader.loadMetadataFromPlatformFile(file);
      if (selection == null) {
        skippedFileNames.add(file.name);
        continue;
      }
      selections.add(selection);
    }

    if (skippedFileNames.isNotEmpty) {
      log(
        'Skipped unreadable receipt files in batch: '
        '${skippedFileNames.join(', ')}',
        name: 'DeviceReceiptInputRepository',
      );
    }
    if (skippedLargeFileNames.isNotEmpty) {
      log(
        'Skipped oversized receipt files in batch: '
        '${skippedLargeFileNames.join(', ')}',
        name: 'DeviceReceiptInputRepository',
      );
    }

    if (selections.isEmpty) {
      throw const _ReceiptInputBatchException(
        'No selected receipt files could be read.',
      );
    }

    return selections;
  }

  Future<FilePickerResult?> _pickFiles({required bool allowMultiple}) {
    return _filePicker.pickFiles(
      allowMultiple: allowMultiple,
      withData: _shouldPreloadFileBytes,
      type: FileType.custom,
      allowedExtensions: ReceiptInputSelectionLoader.allowedFileExtensions,
    );
  }

  Future<ReceiptInputSelection?> _selectionFromFile(PlatformFile file) async {
    return ReceiptInputSelectionLoader.loadFromPlatformFile(file);
  }

  bool get _shouldPreloadFileBytes => kIsWeb;
}

class _ReceiptInputBatchException implements Exception {
  const _ReceiptInputBatchException(this.message);

  final String message;

  @override
  String toString() => '_ReceiptInputBatchException: $message';
}
