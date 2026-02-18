import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
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

const Map<String, String> _mimeTypeByExtension = <String, String>{
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
  'heic': 'image/heic',
  'heif': 'image/heif',
  'pdf': 'application/pdf',
};

@riverpod
ReceiptInputRepository receiptInputRepository(Ref ref) {
  return DeviceReceiptInputRepository();
}

abstract interface class ReceiptInputRepository {
  Future<ReceiptInputResult> pickFromCamera();

  Future<ReceiptInputResult> pickFromFile();
}

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

    return ReceiptInputSelection(
      source: ReceiptInputSource.camera,
      name: fileName,
      mimeType: _mimeTypeForFileName(fileName),
      bytes: await pickedFile.readAsBytes(),
    );
  }

  Future<ReceiptInputSelection?> _pickFileSelection() async {
    final result = await _filePicker.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: _allowedReceiptExtensions,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;
    final bytes = file.bytes;
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
      mimeType: _mimeTypeForFileName(fileName),
      bytes: bytes,
    );
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

String _mimeTypeForFileName(String fileName) {
  final extension = _fileExtension(fileName);
  return _mimeTypeByExtension[extension] ?? _defaultMimeType;
}

String _fileExtension(String fileName) {
  final dotIndex = fileName.lastIndexOf('.');
  if (dotIndex == -1 || dotIndex == fileName.length - 1) {
    return '';
  }

  return fileName.substring(dotIndex + 1).toLowerCase();
}
