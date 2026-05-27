import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/debug/calorie_debug_file_exporter.dart';

void main() {
  test('saveText returns saved result when file picker returns path', () async {
    late String capturedDialogTitle;
    late String capturedFileName;
    late FileType capturedType;
    late List<String>? capturedAllowedExtensions;
    late Uint8List? capturedBytes;
    final exporter = FilePickerCalorieDebugFileExporter(
      saveFile:
          ({
            dialogTitle,
            fileName,
            initialDirectory,
            type = FileType.any,
            allowedExtensions,
            bytes,
            lockParentWindow = false,
          }) async {
            capturedDialogTitle = dialogTitle ?? '';
            capturedFileName = fileName ?? '';
            capturedType = type;
            capturedAllowedExtensions = allowedExtensions;
            capturedBytes = bytes;
            return '/tmp/calorie-debug.txt';
          },
    );

    final result = await exporter.saveText(
      dialogTitle: 'Save debug dump',
      fileName: 'calorie-debug.txt',
      text: 'debug text',
    );

    expect(result, isA<CalorieDebugFileExportSaved>());
    expect(
      (result as CalorieDebugFileExportSaved).path,
      '/tmp/calorie-debug.txt',
    );
    expect(capturedDialogTitle, 'Save debug dump');
    expect(capturedFileName, 'calorie-debug.txt');
    expect(capturedType, FileType.custom);
    expect(capturedAllowedExtensions, const <String>['txt']);
    expect(utf8.decode(capturedBytes ?? Uint8List(0)), 'debug text');
  });

  test(
    'saveText returns canceled result when file picker returns null',
    () async {
      final exporter = FilePickerCalorieDebugFileExporter(
        saveFile:
            ({
              dialogTitle,
              fileName,
              initialDirectory,
              type = FileType.any,
              allowedExtensions,
              bytes,
              lockParentWindow = false,
            }) async {
              return null;
            },
      );

      final result = await exporter.saveText(
        dialogTitle: 'Save debug dump',
        fileName: 'calorie-debug.txt',
        text: 'debug text',
      );

      expect(result, isA<CalorieDebugFileExportCanceled>());
    },
  );
}
