// Exporter interface keeps provider overrides simple across platforms.
// ignore_for_file: one_member_abstracts

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Result from saving a calorie debug text file.
sealed class CalorieDebugFileExportResult {
  /// Creates export result.
  const CalorieDebugFileExportResult();
}

/// Debug text was saved or downloaded.
class CalorieDebugFileExportSaved extends CalorieDebugFileExportResult {
  /// Creates saved result.
  const CalorieDebugFileExportSaved({required this.path});

  /// Saved path, when the platform exposes one.
  final String? path;
}

/// User canceled the save dialog.
class CalorieDebugFileExportCanceled extends CalorieDebugFileExportResult {
  /// Creates canceled result.
  const CalorieDebugFileExportCanceled();
}

/// Saves debug text to a user-chosen file.
abstract class CalorieDebugFileExporter {
  /// Saves [text] as [fileName].
  Future<CalorieDebugFileExportResult> saveText({
    required String fileName,
    required String text,
  });
}

/// Provides the calorie debug file exporter.
final calorieDebugFileExporterProvider = Provider<CalorieDebugFileExporter>(
  (ref) => const FilePickerCalorieDebugFileExporter(),
);

/// `file_picker` implementation for debug text export.
class FilePickerCalorieDebugFileExporter implements CalorieDebugFileExporter {
  /// Creates file-picker exporter.
  const FilePickerCalorieDebugFileExporter();

  @override
  Future<CalorieDebugFileExportResult> saveText({
    required String fileName,
    required String text,
  }) async {
    final path = await FilePicker.saveFile(
      dialogTitle: 'Save calorie debug TXT',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const <String>['txt'],
      bytes: Uint8List.fromList(utf8.encode(text)),
    );

    if (path == null && !kIsWeb) {
      return const CalorieDebugFileExportCanceled();
    }
    return CalorieDebugFileExportSaved(path: path);
  }
}
