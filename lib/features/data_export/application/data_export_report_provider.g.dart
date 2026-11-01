// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_export_report_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The report of the days of [range], read on the device because the diary
/// and the weights are end-to-end encrypted.

@ProviderFor(dataExportReport)
final dataExportReportProvider = DataExportReportFamily._();

/// The report of the days of [range], read on the device because the diary
/// and the weights are end-to-end encrypted.

final class DataExportReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<DataExportReport>,
          DataExportReport,
          FutureOr<DataExportReport>
        >
    with $FutureModifier<DataExportReport>, $FutureProvider<DataExportReport> {
  /// The report of the days of [range], read on the device because the diary
  /// and the weights are end-to-end encrypted.
  DataExportReportProvider._({
    required DataExportReportFamily super.from,
    required DataExportRange super.argument,
  }) : super(
         retry: null,
         name: r'dataExportReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dataExportReportHash();

  @override
  String toString() {
    return r'dataExportReportProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DataExportReport> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DataExportReport> create(Ref ref) {
    final argument = this.argument as DataExportRange;
    return dataExportReport(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DataExportReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dataExportReportHash() => r'fac6b80154cc005e88d47508919f9dadbcdcc92c';

/// The report of the days of [range], read on the device because the diary
/// and the weights are end-to-end encrypted.

final class DataExportReportFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<DataExportReport>, DataExportRange> {
  DataExportReportFamily._()
    : super(
        retry: null,
        name: r'dataExportReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The report of the days of [range], read on the device because the diary
  /// and the weights are end-to-end encrypted.

  DataExportReportProvider call(DataExportRange range) =>
      DataExportReportProvider._(argument: range, from: this);

  @override
  String toString() => r'dataExportReportProvider';
}
