import 'dart:typed_data';

enum ReceiptInputSource { camera, file }

enum ReceiptInputStatus { selected, canceled, unsupported, failed }

enum ReceiptInputBatchStatus { selected, canceled, failed }

abstract final class ReceiptInputErrorCodes {
  static const cameraNotSupported = 'camera_not_supported';
  static const cameraPickFailed = 'camera_pick_failed';
  static const filePickFailed = 'file_pick_failed';
  static const cameraPickUnexpected = 'camera_pick_unexpected';
  static const filePickUnexpected = 'file_pick_unexpected';
}

class ReceiptInputSelection {
  ReceiptInputSelection({
    required this.source,
    required this.name,
    required this.mimeType,
    required this.bytes,
    this.filePath,
  });

  final ReceiptInputSource source;
  final String name;
  final String mimeType;
  final Uint8List bytes;
  final String? filePath;

  bool get hasEmbeddedBytes => bytes.isNotEmpty;
}

class ReceiptInputResult {
  const ReceiptInputResult({
    required this.status,
    this.selection,
    this.errorCode,
  });

  const ReceiptInputResult.selected({required ReceiptInputSelection selection})
    : this(status: ReceiptInputStatus.selected, selection: selection);

  const ReceiptInputResult.canceled()
    : this(status: ReceiptInputStatus.canceled);

  const ReceiptInputResult.unsupported({String? errorCode})
    : this(status: ReceiptInputStatus.unsupported, errorCode: errorCode);

  const ReceiptInputResult.failed({String? errorCode})
    : this(status: ReceiptInputStatus.failed, errorCode: errorCode);

  final ReceiptInputStatus status;
  final ReceiptInputSelection? selection;
  final String? errorCode;
}

class ReceiptInputBatchResult {
  const ReceiptInputBatchResult._({
    required this.status,
    required this.selections,
    this.errorCode,
  });

  const ReceiptInputBatchResult.selected({
    required List<ReceiptInputSelection> selections,
  }) : this._(status: ReceiptInputBatchStatus.selected, selections: selections);

  const ReceiptInputBatchResult.canceled()
    : this._(
        status: ReceiptInputBatchStatus.canceled,
        selections: const <ReceiptInputSelection>[],
      );

  const ReceiptInputBatchResult.failed({String? errorCode})
    : this._(
        status: ReceiptInputBatchStatus.failed,
        selections: const <ReceiptInputSelection>[],
        errorCode: errorCode,
      );

  final ReceiptInputBatchStatus status;
  final List<ReceiptInputSelection> selections;
  final String? errorCode;
}
