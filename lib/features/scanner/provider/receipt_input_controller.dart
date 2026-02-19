import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/scanner/data/receipt_input_repository.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';

part 'receipt_input_controller.g.dart';

@riverpod
class ReceiptInputController extends _$ReceiptInputController {
  @override
  FutureOr<ReceiptInputResult?> build() {
    return null;
  }

  bool get isCameraSupported {
    return ref.read(receiptCameraSupportedProvider);
  }

  Future<ReceiptInputResult> pickFromCamera() {
    if (!isCameraSupported) {
      return Future<ReceiptInputResult>.value(
        const ReceiptInputResult.unsupported(
          errorCode: ReceiptInputErrorCodes.cameraNotSupported,
        ),
      );
    }

    return _pickReceipt(
      action: () => ref.read(receiptInputRepositoryProvider).pickFromCamera(),
      fallbackErrorCode: ReceiptInputErrorCodes.cameraPickUnexpected,
    );
  }

  Future<ReceiptInputResult> pickFromFile() {
    return _pickReceipt(
      action: () => ref.read(receiptInputRepositoryProvider).pickFromFile(),
      fallbackErrorCode: ReceiptInputErrorCodes.filePickUnexpected,
    );
  }

  Future<ReceiptInputResult> _pickReceipt({
    required Future<ReceiptInputResult> Function() action,
    required String fallbackErrorCode,
  }) async {
    if (!ref.mounted) {
      return ReceiptInputResult.failed(errorCode: fallbackErrorCode);
    }

    state = const AsyncLoading();

    try {
      final result = await action();
      if (!ref.mounted) {
        return ReceiptInputResult.failed(errorCode: fallbackErrorCode);
      }

      state = AsyncData(result);
      return result;
    } catch (error, stackTrace) {
      log(
        'Receipt input action failed (code: $fallbackErrorCode)',
        name: 'ReceiptInputController',
        error: error,
        stackTrace: stackTrace,
      );
      final failure = ReceiptInputResult.failed(errorCode: fallbackErrorCode);
      if (ref.mounted) {
        state = AsyncData(failure);
      }
      return failure;
    }
  }
}
