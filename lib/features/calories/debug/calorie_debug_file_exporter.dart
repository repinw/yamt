// Exporter interface keeps provider overrides simple across platforms.
// ignore_for_file: one_member_abstracts

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calorie_debug_file_exporter.g.dart';

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
    required String dialogTitle,
    required String fileName,
    required String text,
  });
}

/// Save-file callback used by [FilePickerCalorieDebugFileExporter].
typedef CalorieDebugSaveFileCallback =
    Future<String?> Function({
      String? dialogTitle,
      String? fileName,
      String? initialDirectory,
      FileType type,
      List<String>? allowedExtensions,
      Uint8List? bytes,
      bool lockParentWindow,
    });

/// Provides the calorie debug file exporter.
@riverpod
CalorieDebugFileExporter calorieDebugFileExporter(Ref ref) {
  return const FilePickerCalorieDebugFileExporter();
}

/// `file_picker` implementation for debug text export.
class FilePickerCalorieDebugFileExporter implements CalorieDebugFileExporter {
  /// Creates file-picker exporter.
  const FilePickerCalorieDebugFileExporter({
    CalorieDebugSaveFileCallback? saveFile,
  }) : _saveFile = saveFile;

  final CalorieDebugSaveFileCallback? _saveFile;

  @override
  Future<CalorieDebugFileExportResult> saveText({
    required String dialogTitle,
    required String fileName,
    required String text,
  }) async {
    final saveFile = _saveFile ?? FilePicker.saveFile;
    final path = await saveFile(
      dialogTitle: dialogTitle,
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
