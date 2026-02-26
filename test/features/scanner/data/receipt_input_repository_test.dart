import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yamt/features/scanner/data/receipt_input_repository.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

const String _missingPath = '/tmp/does-not-exist.jpg';

class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker({this.onPickImage});

  final Future<XFile?> Function(ImageSource source)? onPickImage;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) {
    final callback = onPickImage;
    if (callback != null) {
      return callback(source);
    }
    return Future<XFile?>.value(null);
  }
}

class _FakeFilePicker extends FilePicker {
  _FakeFilePicker({required this.onPickFiles});

  final Future<FilePickerResult?> Function({
    required bool withData,
    required bool allowMultiple,
    required List<String>? allowedExtensions,
  })
  onPickFiles;

  bool? lastWithData;
  bool? lastAllowMultiple;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    lastWithData = withData;
    lastAllowMultiple = allowMultiple;
    return onPickFiles(
      withData: withData,
      allowMultiple: allowMultiple,
      allowedExtensions: allowedExtensions,
    );
  }
}

void main() {
  test(
    'pickFromFile falls back to octet-stream for unknown file type',
    () async {
      final filePicker = _FakeFilePicker(
        onPickFiles:
            ({
              required withData,
              required allowMultiple,
              required allowedExtensions,
            }) async {
              return FilePickerResult([
                PlatformFile(
                  name: 'receipt_upload',
                  size: 4,
                  bytes: Uint8List.fromList(<int>[0x00, 0x11, 0x22, 0x33]),
                ),
              ]);
            },
      );

      final repository = DeviceReceiptInputRepository(
        imagePicker: _FakeImagePicker(),
        filePicker: filePicker,
      );

      final result = await repository.pickFromFile();

      expect(result.status, ReceiptInputStatus.selected);
      expect(result.selection, isNotNull);
      expect(result.selection!.mimeType, 'application/octet-stream');
      expect(filePicker.lastWithData, isFalse);
      expect(filePicker.lastAllowMultiple, isFalse);
    },
  );

  test('pickFromCamera resolves filename from windows-style path', () async {
    final imagePicker = _FakeImagePicker(
      onPickImage: (source) async {
        return XFile.fromData(
          Uint8List.fromList(<int>[0x01, 0x02, 0x03]),
          path: r'C:\receipts\scan_123.jpg',
        );
      },
    );
    final filePicker = _FakeFilePicker(
      onPickFiles:
          ({
            required withData,
            required allowMultiple,
            required allowedExtensions,
          }) async {
            return null;
          },
    );

    final repository = DeviceReceiptInputRepository(
      imagePicker: imagePicker,
      filePicker: filePicker,
    );

    final result = await repository.pickFromCamera();

    expect(result.status, ReceiptInputStatus.selected);
    expect(result.selection, isNotNull);
    expect(result.selection!.name, 'scan_123.jpg');
  });

  test(
    'pickFromFile loads bytes from path when memory bytes are null',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'receipt-input-repo-test',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final expectedBytes = Uint8List.fromList(<int>[0xAA, 0xBB, 0xCC]);
      final file = File('${tempDir.path}/receipt.pdf');
      await file.writeAsBytes(expectedBytes);

      final filePicker = _FakeFilePicker(
        onPickFiles:
            ({
              required withData,
              required allowMultiple,
              required allowedExtensions,
            }) async {
              return FilePickerResult([
                PlatformFile(
                  name: 'receipt.pdf',
                  size: expectedBytes.length,
                  path: file.path,
                ),
              ]);
            },
      );

      final repository = DeviceReceiptInputRepository(
        imagePicker: _FakeImagePicker(),
        filePicker: filePicker,
      );

      final result = await repository.pickFromFile();

      expect(result.status, ReceiptInputStatus.selected);
      expect(result.selection, isNotNull);
      expect(result.selection!.bytes, orderedEquals(expectedBytes));
      expect(result.selection!.mimeType, 'application/pdf');
      expect(filePicker.lastWithData, isFalse);
      expect(filePicker.lastAllowMultiple, isFalse);
    },
  );

  test(
    'pickFromFiles allows multi-select and returns all selections',
    () async {
      final filePicker = _FakeFilePicker(
        onPickFiles:
            ({
              required withData,
              required allowMultiple,
              required allowedExtensions,
            }) async {
              return FilePickerResult([
                PlatformFile(
                  name: 'one.jpg',
                  size: 3,
                  bytes: Uint8List.fromList(<int>[0x01, 0x02, 0x03]),
                ),
                PlatformFile(
                  name: 'two.pdf',
                  size: 4,
                  bytes: Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46]),
                ),
              ]);
            },
      );

      final repository = DeviceReceiptInputRepository(
        imagePicker: _FakeImagePicker(),
        filePicker: filePicker,
      );

      final result = await repository.pickFromFiles();

      expect(result.status, ReceiptInputBatchStatus.selected);
      expect(result.selections, hasLength(2));
      expect(result.selections.first.name, 'one.jpg');
      expect(result.selections.last.name, 'two.pdf');
      expect(filePicker.lastAllowMultiple, isTrue);
      expect(filePicker.lastWithData, isFalse);
    },
  );

  test(
    'pickFromFiles keeps metadata without eagerly loading file path bytes',
    () async {
      final filePicker = _FakeFilePicker(
        onPickFiles:
            ({
              required withData,
              required allowMultiple,
              required allowedExtensions,
            }) async {
              return FilePickerResult([
                PlatformFile(
                  name: 'later-read.jpg',
                  size: 8,
                  path: _missingPath,
                ),
              ]);
            },
      );

      final repository = DeviceReceiptInputRepository(
        imagePicker: _FakeImagePicker(),
        filePicker: filePicker,
      );

      final result = await repository.pickFromFiles();

      expect(result.status, ReceiptInputBatchStatus.selected);
      expect(result.selections, hasLength(1));
      expect(result.selections.single.name, 'later-read.jpg');
      expect(result.selections.single.bytes, isEmpty);
      expect(result.selections.single.filePath, _missingPath);
    },
  );

  test('pickFromFiles returns canceled when picker is dismissed', () async {
    final filePicker = _FakeFilePicker(
      onPickFiles:
          ({
            required withData,
            required allowMultiple,
            required allowedExtensions,
          }) async {
            return null;
          },
    );

    final repository = DeviceReceiptInputRepository(
      imagePicker: _FakeImagePicker(),
      filePicker: filePicker,
    );

    final result = await repository.pickFromFiles();

    expect(result.status, ReceiptInputBatchStatus.canceled);
    expect(result.selections, isEmpty);
    expect(filePicker.lastAllowMultiple, isTrue);
  });

  test(
    'pickFromFiles returns failed when selected file cannot be read',
    () async {
      final filePicker = _FakeFilePicker(
        onPickFiles:
            ({
              required withData,
              required allowMultiple,
              required allowedExtensions,
            }) async {
              return FilePickerResult([
                PlatformFile(name: 'broken.pdf', size: 4),
              ]);
            },
      );

      final repository = DeviceReceiptInputRepository(
        imagePicker: _FakeImagePicker(),
        filePicker: filePicker,
      );

      final result = await repository.pickFromFiles();

      expect(result.status, ReceiptInputBatchStatus.failed);
      expect(result.errorCode, ReceiptInputErrorCodes.filePickFailed);
    },
  );

  test(
    'pickFromFiles skips unreadable files when at least one file is valid',
    () async {
      final filePicker = _FakeFilePicker(
        onPickFiles:
            ({
              required withData,
              required allowMultiple,
              required allowedExtensions,
            }) async {
              return FilePickerResult([
                PlatformFile(name: 'broken.pdf', size: 4),
                PlatformFile(
                  name: 'ok.jpg',
                  size: 3,
                  bytes: Uint8List.fromList(<int>[0x01, 0x02, 0x03]),
                ),
              ]);
            },
      );

      final repository = DeviceReceiptInputRepository(
        imagePicker: _FakeImagePicker(),
        filePicker: filePicker,
      );

      final result = await repository.pickFromFiles();

      expect(result.status, ReceiptInputBatchStatus.selected);
      expect(result.selections, hasLength(1));
      expect(result.selections.single.name, 'ok.jpg');
    },
  );
}
