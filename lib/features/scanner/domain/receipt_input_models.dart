import 'dart:typed_data';

/// Defines receipt input source.
enum ReceiptInputSource {
  /// Camera.
  camera,

  /// File.
  file,
}

/// Defines receipt input status.
enum ReceiptInputStatus {
  /// Selected.
  selected,

  /// Canceled.
  canceled,

  /// Unsupported.
  unsupported,

  /// Failed.
  failed,
}

/// Defines receipt input batch status.
enum ReceiptInputBatchStatus {
  /// Selected.
  selected,

  /// Canceled.
  canceled,

  /// Failed.
  failed,
}

/// Defines receipt input error codes.
abstract final class ReceiptInputErrorCodes {
  /// The camera not supported.
  static const cameraNotSupported = 'camera_not_supported';

  /// The camera pick failed.
  static const cameraPickFailed = 'camera_pick_failed';

  /// The file pick failed.
  static const filePickFailed = 'file_pick_failed';

  /// The camera pick unexpected.
  static const cameraPickUnexpected = 'camera_pick_unexpected';

  /// The file pick unexpected.
  static const filePickUnexpected = 'file_pick_unexpected';
}

/// Defines receipt input selection.
class ReceiptInputSelection {
  /// Creates an instance.
  ReceiptInputSelection({
    required this.source,
    required this.name,
    required this.mimeType,
    required this.bytes,
    this.filePath,
  });

  /// The source.
  final ReceiptInputSource source;

  /// The name.
  final String name;

  /// The mime type.
  final String mimeType;

  /// The bytes.
  final Uint8List bytes;

  /// The file path.
  final String? filePath;

  /// Whether embedded bytes.
  bool get hasEmbeddedBytes => bytes.isNotEmpty;
}

/// Defines receipt input result.
class ReceiptInputResult {
  /// The receipt input result.
  const ReceiptInputResult({
    required this.status,
    this.selection,
    this.errorCode,
  });

  /// Creates a [ReceiptInputResult] for selected.
  const ReceiptInputResult.selected({required ReceiptInputSelection selection})
    : this(status: ReceiptInputStatus.selected, selection: selection);

  /// Creates a [ReceiptInputResult] for canceled.
  const ReceiptInputResult.canceled()
    : this(status: ReceiptInputStatus.canceled);

  /// Creates a [ReceiptInputResult] for failed.
  const ReceiptInputResult.failed({String? errorCode})
    : this(status: ReceiptInputStatus.failed, errorCode: errorCode);

  /// The status.
  final ReceiptInputStatus status;

  /// The selection.
  final ReceiptInputSelection? selection;

  /// The error code.
  final String? errorCode;
}

/// Defines receipt input batch result.
class ReceiptInputBatchResult {
  const ReceiptInputBatchResult._({
    required this.status,
    required this.selections,
    this.errorCode,
  });

  /// Creates a [ReceiptInputBatchResult] for selected.
  const ReceiptInputBatchResult.selected({
    required List<ReceiptInputSelection> selections,
  }) : this._(status: ReceiptInputBatchStatus.selected, selections: selections);

  /// Creates a [ReceiptInputBatchResult] for canceled.
  const ReceiptInputBatchResult.canceled()
    : this._(
        status: ReceiptInputBatchStatus.canceled,
        selections: const <ReceiptInputSelection>[],
      );

  /// Creates a [ReceiptInputBatchResult] for failed.
  const ReceiptInputBatchResult.failed({String? errorCode})
    : this._(
        status: ReceiptInputBatchStatus.failed,
        selections: const <ReceiptInputSelection>[],
        errorCode: errorCode,
      );

  /// The status.
  final ReceiptInputBatchStatus status;

  /// The selections.
  final List<ReceiptInputSelection> selections;

  /// The error code.
  final String? errorCode;
}
