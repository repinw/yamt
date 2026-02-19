import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/data/receipt_analysis_repository.dart';
import 'package:yamt/features/inventory/domain/receipt_analysis_models.dart';
import 'package:yamt/features/inventory/domain/receipt_input_models.dart';

part 'receipt_analysis_controller.g.dart';

@riverpod
class ReceiptAnalysisController extends _$ReceiptAnalysisController {
  @override
  FutureOr<ReceiptAnalysisResult?> build() {
    return null;
  }

  Future<ReceiptAnalysisResult> analyzeSelection(
    ReceiptInputSelection selection,
  ) async {
    if (!ref.mounted) {
      return const ReceiptAnalysisResult.failed(
        errorCode: ReceiptAnalysisErrorCodes.unexpected,
      );
    }

    state = const AsyncLoading();

    try {
      final repository = ref.read(receiptAnalysisRepositoryProvider);
      final result = await repository.analyzeSelection(selection);
      if (!ref.mounted) {
        return const ReceiptAnalysisResult.failed(
          errorCode: ReceiptAnalysisErrorCodes.unexpected,
        );
      }

      state = AsyncData(result);
      return result;
    } catch (error, stackTrace) {
      log(
        'Receipt analysis failed',
        name: 'ReceiptAnalysisController',
        error: error,
        stackTrace: stackTrace,
      );
      const failure = ReceiptAnalysisResult.failed(
        errorCode: ReceiptAnalysisErrorCodes.unexpected,
      );
      if (ref.mounted) {
        state = AsyncData(failure);
      }
      return failure;
    }
  }
}
