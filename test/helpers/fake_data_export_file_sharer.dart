import 'dart:async';
import 'dart:ui';

import 'package:yamt/features/data_export/data/data_export_file_sharer.dart';

/// Records the files that the export shares or saves; asynchronous like the
/// real share sheet and save dialog.
class FakeDataExportFileSharer implements DataExportFileSharer {
  /// Creates a sharer whose save dialog gives [saveResult].
  new({this.saveResult = true});

  /// What the save dialog answers: false when the user closes it.
  bool saveResult;

  /// Thrown by [shareFiles] when set.
  Exception? shareError;

  /// Thrown by [saveFile] when set.
  Exception? saveError;

  /// The file lists handed to the share sheet.
  final List<List<DataExportFile>> shared = [];

  /// The origins handed to the share sheet.
  final List<Rect?> origins = [];

  /// The files handed to the save dialog.
  final List<DataExportFile> saved = [];

  @override
  Future<void> shareFiles(List<DataExportFile> files, {Rect? origin}) async {
    await Future<void>.delayed(Duration.zero);
    if (shareError case final error?) throw error;
    shared.add(files);
    origins.add(origin);
  }

  @override
  Future<bool> saveFile(DataExportFile file) async {
    await Future<void>.delayed(Duration.zero);
    if (saveError case final error?) throw error;
    saved.add(file);
    return saveResult;
  }
}
