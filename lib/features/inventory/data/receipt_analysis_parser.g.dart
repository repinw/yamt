// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_analysis_parser.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(receiptAnalysisParser)
final receiptAnalysisParserProvider = ReceiptAnalysisParserProvider._();

final class ReceiptAnalysisParserProvider
    extends
        $FunctionalProvider<
          ReceiptAnalysisParser,
          ReceiptAnalysisParser,
          ReceiptAnalysisParser
        >
    with $Provider<ReceiptAnalysisParser> {
  ReceiptAnalysisParserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptAnalysisParserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptAnalysisParserHash();

  @$internal
  @override
  $ProviderElement<ReceiptAnalysisParser> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptAnalysisParser create(Ref ref) {
    return receiptAnalysisParser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptAnalysisParser value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptAnalysisParser>(value),
    );
  }
}

String _$receiptAnalysisParserHash() =>
    r'4165a721e223485f80e791b4f6b9aff79c57f434';
