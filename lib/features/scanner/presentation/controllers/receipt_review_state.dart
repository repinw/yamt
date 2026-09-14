import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';

part 'receipt_review_state.freezed.dart';

/// UI state for the receipt review screen.
@freezed
abstract class ReceiptReviewState with _$ReceiptReviewState {
  /// Creates an instance of [ReceiptReviewState].
  const factory ReceiptReviewState({
    /// Currently reviewed receipt.
    required ScannedReceipt receipt,

    /// Whether saving to inventory is in progress.
    @Default(false) bool isSaving,

    /// Whether product / barcode resolution is in progress.
    @Default(false) bool isResolving,

    /// Whether the receipt was saved successfully.
    @Default(false) bool saveSuccess,

    /// Optional error message for snackbars or banners.
    String? errorMessage,
  }) = _ReceiptReviewState;

  const ReceiptReviewState._();
}
