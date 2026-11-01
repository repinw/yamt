import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'data_export_file_sharer.g.dart';

/// One written export file.
@immutable
class DataExportFile {
  /// Creates a file named [name] with [bytes] of [mimeType].
  const new({required this.name, required this.mimeType, required this.bytes});

  /// File name with its extension.
  final String name;

  /// MIME type for the share sheet.
  final String mimeType;

  /// The content.
  final Uint8List bytes;
}

/// Provides the export file sharer.
@riverpod
DataExportFileSharer dataExportFileSharer(Ref ref) =>
    const DataExportFileSharer();

/// Hands export files to the system share sheet or saves them.
class DataExportFileSharer {
  /// Creates the sharer.
  const new();

  /// Opens the share sheet with [files]. [origin] anchors the sheet on
  /// tablets. Closing the sheet without picking an app is no failure.
  Future<void> shareFiles(List<DataExportFile> files, {Rect? origin}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          for (final file in files)
            XFile.fromData(
              file.bytes,
              mimeType: file.mimeType,
              name: file.name,
            ),
        ],
        fileNameOverrides: [for (final file in files) file.name],
        sharePositionOrigin: origin,
      ),
    );
  }

  /// Saves [file] where the user picks in the system save dialog; false
  /// when the user closed the dialog.
  Future<bool> saveFile(DataExportFile file) async {
    final uri = await FilePicker.saveFile(
      fileName: file.name,
      bytes: file.bytes,
      mimeType: file.mimeType,
    );
    return uri != null;
  }
}
