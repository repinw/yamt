import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/data/receipt_analysis_parser.dart';
import 'package:yamt/features/inventory/data/receipt_analysis_repository.dart';
import 'package:yamt/features/inventory/domain/receipt_analysis_models.dart';
import 'package:yamt/features/inventory/domain/receipt_input_models.dart';

part 'receipt_analysis_controller.g.dart';

@Riverpod(keepAlive: true)
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
      final repositoryResult = await repository.analyzeSelection(selection);
      final result = _parseRepositoryResult(repositoryResult);
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

  ReceiptAnalysisResult _parseRepositoryResult(
    ReceiptAnalysisResult repositoryResult,
  ) {
    if (!repositoryResult.isSuccess) {
      return repositoryResult;
    }

    final rawResponse = repositoryResult.rawResponse;
    if (rawResponse == null || rawResponse.trim().isEmpty) {
      return const ReceiptAnalysisResult.failed(
        errorCode: ReceiptAnalysisErrorCodes.parseFailed,
      );
    }

    final parser = ref.read(receiptAnalysisParserProvider);
    try {
      final extraction = parser.parse(rawResponse);
      return ReceiptAnalysisResult.succeeded(
        rawResponse: rawResponse,
        extraction: extraction,
      );
    } catch (error, stackTrace) {
      log(
        'Receipt analysis parse failed',
        name: 'ReceiptAnalysisController',
        error: error,
        stackTrace: stackTrace,
      );
      return const ReceiptAnalysisResult.failed(
        errorCode: ReceiptAnalysisErrorCodes.parseFailed,
      );
    }
  }
}
