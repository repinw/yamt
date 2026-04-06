import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yamt/features/scanner/data/receipt_input_selection_loader.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

class _OversizedTestXFile extends XFile {
  _OversizedTestXFile(super.path);

  bool readAsBytesCalled = false;

  @override
  Future<int> length() async {
    return 12 * 1024 * 1024 + 1;
  }

  @override
  Future<Uint8List> readAsBytes() async {
    readAsBytesCalled = true;
    return Uint8List.fromList(<int>[0x01, 0x02, 0x03]);
  }
}

void main() {
  test('loadSharedSelectionsFromPaths deduplicates files and skips '
      'unsupported ones', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'receipt-input-selection-loader',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final imageFile = File('${tempDir.path}/shared_receipt.jpg');
    await imageFile.writeAsBytes(<int>[0x01, 0x02, 0x03]);

    final textFile = File('${tempDir.path}/notes.txt');
    await textFile.writeAsBytes(<int>[0x04, 0x05, 0x06]);

    final selections =
        await ReceiptInputSelectionLoader.loadSharedSelectionsFromPaths(
          <String>['', imageFile.path, textFile.path, imageFile.path],
        );

    expect(selections, hasLength(1));
    expect(selections.single.name, 'shared_receipt.jpg');
    expect(selections.single.mimeType, 'image/jpeg');
    expect(
      selections.single.bytes,
      orderedEquals(Uint8List.fromList(<int>[0x01, 0x02, 0x03])),
    );
  });

  test('loadSharedSelectionsFromPaths skips oversized shared files', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'receipt-input-selection-loader',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final validImageFile = File('${tempDir.path}/shared_receipt.jpg');
    await validImageFile.writeAsBytes(<int>[0x01, 0x02, 0x03]);

    final oversizedImageFile = File('${tempDir.path}/oversized_receipt.jpg');
    await oversizedImageFile.writeAsBytes(
      List<int>.filled(12 * 1024 * 1024 + 1, 0x01),
    );

    final selections =
        await ReceiptInputSelectionLoader.loadSharedSelectionsFromPaths(
          <String>[oversizedImageFile.path, validImageFile.path],
        );

    expect(selections, hasLength(1));
    expect(selections.single.name, 'shared_receipt.jpg');
  });

  test('loadSharedSelectionsFromPaths skips unreadable shared files and keeps '
      'valid ones', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'receipt-input-selection-loader',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final validImageFile = File('${tempDir.path}/shared_receipt.jpg');
    await validImageFile.writeAsBytes(<int>[0x01, 0x02, 0x03]);

    final selections =
        await ReceiptInputSelectionLoader.loadSharedSelectionsFromPaths(
          <String>['${tempDir.path}/missing.jpg', validImageFile.path],
        );

    expect(selections, hasLength(1));
    expect(selections.single.name, 'shared_receipt.jpg');
  });

  test('loadFromXFile preserves camera source and file name', () async {
    final file = XFile.fromData(
      Uint8List.fromList(<int>[0x01, 0x02, 0x03]),
      path: r'C:\receipts\scan_123.jpg',
    );

    final selection = await ReceiptInputSelectionLoader.loadFromXFile(
      file,
      source: ReceiptInputSource.camera,
    );

    expect(selection.source, ReceiptInputSource.camera);
    expect(selection.name, 'scan_123.jpg');
    expect(selection.mimeType, 'image/jpeg');
  });

  test(
    'loadFromXFile rejects oversized files before loading them into memory',
    () async {
      final oversizedFile = _OversizedTestXFile('oversized_receipt.jpg');

      await expectLater(
        () => ReceiptInputSelectionLoader.loadFromXFile(
          oversizedFile,
          source: ReceiptInputSource.file,
        ),
        throwsA(
          predicate(
            (Object error) =>
                error.toString().contains('Receipt file exceeds size limit'),
          ),
        ),
      );

      expect(oversizedFile.readAsBytesCalled, isFalse);
    },
  );

  test('loadMetadataFromPlatformFile keeps path-backed files lazy', () {
    const filePath = '/tmp/later-read.jpg';

    final selection = ReceiptInputSelectionLoader.loadMetadataFromPlatformFile(
      PlatformFile(name: 'later-read.jpg', size: 8, path: filePath),
    );

    expect(selection, isNotNull);
    expect(selection!.name, 'later-read.jpg');
    expect(selection.bytes, isEmpty);
    expect(selection.filePath, filePath);
  });
}
