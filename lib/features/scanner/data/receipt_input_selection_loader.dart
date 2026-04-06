import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

const String _defaultMimeType = 'application/octet-stream';
const String _pdfMimeType = 'application/pdf';
const String _fallbackCameraFileName = 'camera-image.jpg';
const String _fallbackUploadFileName = 'receipt-upload';
const int _mimeHeaderLength = 32;
const int _maxReceiptInputBytes = 12 * 1024 * 1024;
const String _receiptInputSelectionLoaderLogName =
    'ReceiptInputSelectionLoader';
final Uint8List _emptySelectionBytes = Uint8List(0);

/// Builds receipt input selections from picked files and shared file paths.
abstract final class ReceiptInputSelectionLoader {
  /// Supported file extensions for receipt uploads.
  static const List<String> allowedFileExtensions = <String>[
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
    'pdf',
  ];

  /// Converts shared file paths into fully loaded receipt selections.
  static Future<List<ReceiptInputSelection>> loadSharedSelectionsFromPaths(
    Iterable<String> filePaths,
  ) async {
    final selections = <ReceiptInputSelection>[];
    final seenPaths = <String>{};
    for (final filePath in filePaths) {
      final normalizedPath = filePath.trim();
      if (normalizedPath.isEmpty || !seenPaths.add(normalizedPath)) {
        continue;
      }

      try {
        final selection = await _loadSharedSelection(normalizedPath);
        if (selection != null) {
          selections.add(selection);
        }
      } catch (error, stackTrace) {
        log(
          'Skipped shared receipt file: $normalizedPath',
          name: _receiptInputSelectionLoaderLogName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return selections;
  }

  /// Loads a picked file completely, including bytes, for single-file scans.
  static Future<ReceiptInputSelection?> loadFromPlatformFile(
    PlatformFile file,
  ) async {
    if (_isFileTooLarge(file)) {
      throw _ReceiptInputSelectionLoaderException(
        'Receipt file exceeds size limit: ${file.name}',
      );
    }

    final bytes = await _resolveFileBytes(file);
    if (bytes == null) {
      return null;
    }
    if (bytes.length > _maxReceiptInputBytes) {
      throw _ReceiptInputSelectionLoaderException(
        'Receipt file exceeds size limit: ${file.name}',
      );
    }

    return _buildSelection(
      source: ReceiptInputSource.file,
      primaryName: file.name,
      filePath: file.path,
      bytes: bytes,
      fallbackName: _fallbackUploadFileName,
    );
  }

  /// Loads a captured or shared file completely, including bytes.
  static Future<ReceiptInputSelection> loadFromXFile(
    XFile file, {
    required ReceiptInputSource source,
  }) async {
    final length = await file.length();
    if (length > _maxReceiptInputBytes) {
      throw _ReceiptInputSelectionLoaderException(
        'Receipt file exceeds size limit: ${file.name}',
      );
    }

    final bytes = await file.readAsBytes();
    if (bytes.length > _maxReceiptInputBytes) {
      throw _ReceiptInputSelectionLoaderException(
        'Receipt file exceeds size limit: ${file.name}',
      );
    }

    return _buildSelection(
      source: source,
      primaryName: file.name,
      filePath: file.path,
      bytes: bytes,
      fallbackName: _fallbackNameFor(source),
    )!;
  }

  /// Builds metadata-only selections for batch processing.
  static ReceiptInputSelection? loadMetadataFromPlatformFile(
    PlatformFile file,
  ) {
    final inMemoryBytes = file.bytes;
    final path = file.path;
    final hasLoadablePath = path != null && path.isNotEmpty;
    if (inMemoryBytes == null && !hasLoadablePath) {
      return null;
    }

    return _buildSelection(
      source: ReceiptInputSource.file,
      primaryName: file.name,
      filePath: path,
      bytes: inMemoryBytes,
      fallbackName: _fallbackUploadFileName,
    );
  }

  /// Returns whether the provided file is above the accepted size limit.
  static bool isFileTooLarge(PlatformFile file) {
    return _isFileTooLarge(file);
  }
}

Future<ReceiptInputSelection?> _loadSharedSelection(String filePath) async {
  final sharedFile = XFile(filePath);
  ReceiptInputSelection selection;
  try {
    selection = await ReceiptInputSelectionLoader.loadFromXFile(
      sharedFile,
      source: ReceiptInputSource.file,
    );
  } on _ReceiptInputSelectionLoaderException {
    return null;
  }
  if (selection.bytes.isEmpty) {
    return null;
  }
  if (!_isSupportedReceiptMimeType(selection.mimeType)) {
    return null;
  }
  return selection;
}

ReceiptInputSelection? _buildSelection({
  required ReceiptInputSource source,
  required String primaryName,
  required String fallbackName,
  required Uint8List? bytes,
  String? filePath,
}) {
  final fileName = _resolvedFileName(
    primaryName: primaryName,
    fallbackPath: filePath,
    fallbackName: fallbackName,
  );
  final mimeType = _detectMimeType(fileName: fileName, bytes: bytes);

  return ReceiptInputSelection(
    source: source,
    name: fileName,
    mimeType: mimeType,
    bytes: bytes ?? _emptySelectionBytes,
    filePath: filePath,
  );
}

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

bool _isFileTooLarge(PlatformFile file) {
  final bytesLength = file.bytes?.length ?? 0;
  final resolvedLength = bytesLength > file.size ? bytesLength : file.size;
  if (resolvedLength <= 0) {
    return false;
  }
  return resolvedLength > _maxReceiptInputBytes;
}

String _fallbackNameFor(ReceiptInputSource source) {
  return switch (source) {
    ReceiptInputSource.camera => _fallbackCameraFileName,
    ReceiptInputSource.file => _fallbackUploadFileName,
  };
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

String _detectMimeType({required String fileName, Uint8List? bytes}) {
  List<int>? headerBytes;
  if (bytes != null && bytes.isNotEmpty) {
    final headerLength = bytes.length < _mimeHeaderLength
        ? bytes.length
        : _mimeHeaderLength;
    headerBytes = bytes.sublist(0, headerLength);
  }

  final mimeType = lookupMimeType(fileName, headerBytes: headerBytes);
  if (mimeType == null || mimeType.isEmpty) {
    return _defaultMimeType;
  }

  return mimeType;
}

bool _isSupportedReceiptMimeType(String mimeType) {
  return mimeType == _pdfMimeType || mimeType.startsWith('image/');
}

class _ReceiptInputSelectionLoaderException implements Exception {
  const _ReceiptInputSelectionLoaderException(this.message);

  final String message;

  @override
  String toString() {
    return '_ReceiptInputSelectionLoaderException: $message';
  }
}
