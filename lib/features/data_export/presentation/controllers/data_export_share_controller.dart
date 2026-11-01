import 'package:flutter/services.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/data_export/application/data_export_files.dart';
import 'package:yamt/features/data_export/application/data_export_labels.dart';
import 'package:yamt/features/data_export/application/data_export_markdown_writer.dart';
import 'package:yamt/features/data_export/data/data_export_file_sharer.dart';
import 'package:yamt/features/data_export/domain/data_export_purpose.dart';
import 'package:yamt/features/data_export/domain/data_export_report.dart';

part 'data_export_share_controller.g.dart';

/// How an export ended.
enum DataExportOutcome {
  /// The share sheet opened; closing it without an app counts too.
  shared,

  /// The AI text was copied to the clipboard.
  copied,

  /// The file was saved on the device.
  saved,

  /// The user closed the save dialog.
  canceled,

  /// Writing, sharing, or saving failed.
  failed,
}

/// Writes the export files and shares or saves them.
@riverpod
class DataExportShareController extends _$DataExportShareController {
  @override
  FutureOr<void> build() {}

  /// Shares the files of [purpose] for [report], or saves them when
  /// [DataExportPurpose.saves].
  Future<DataExportOutcome> share({
    required DataExportReport report,
    required DataExportPurpose purpose,
    required DataExportLabels labels,
    Rect? origin,
  }) async {
    state = const AsyncLoading();
    final sharer = ref.read(dataExportFileSharerProvider);
    final result = await AsyncValue.guard(() async {
      final files = await writeDataExportFiles(
        report: report,
        purpose: purpose,
        labels: labels,
      );
      if (!purpose.saves) {
        await sharer.shareFiles(files, origin: origin);
        return DataExportOutcome.shared;
      }
      for (final file in files) {
        if (!await sharer.saveFile(file)) return DataExportOutcome.canceled;
      }
      return DataExportOutcome.saved;
    });
    if (!ref.mounted) return DataExportOutcome.failed;
    state = result.hasError
        ? AsyncError<void>(result.error!, result.stackTrace!)
        : const AsyncData<void>(null);
    return result.value ?? DataExportOutcome.failed;
  }

  /// Copies the AI text of [report] to the clipboard, for AI apps that
  /// take no file.
  Future<DataExportOutcome> copy({
    required DataExportReport report,
    required DataExportLabels labels,
  }) async {
    final result = await AsyncValue.guard(() async {
      await Clipboard.setData(
        ClipboardData(text: writeDataExportMarkdown(report, labels)),
      );
      return DataExportOutcome.copied;
    });
    if (!ref.mounted) return DataExportOutcome.failed;
    return result.value ?? DataExportOutcome.failed;
  }
}
