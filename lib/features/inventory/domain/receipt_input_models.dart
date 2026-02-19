import 'dart:typed_data';

enum ReceiptInputSource { camera, file }

enum ReceiptInputStatus { selected, canceled, unsupported, failed }

abstract final class ReceiptInputErrorCodes {
  static const cameraNotSupported = 'camera_not_supported';
  static const cameraPickFailed = 'camera_pick_failed';
  static const filePickFailed = 'file_pick_failed';
  static const cameraPickUnexpected = 'camera_pick_unexpected';
  static const filePickUnexpected = 'file_pick_unexpected';
}

class ReceiptInputSelection {
  const ReceiptInputSelection({
    required this.source,
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final ReceiptInputSource source;
  final String name;
  final String mimeType;
  final Uint8List bytes;
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
