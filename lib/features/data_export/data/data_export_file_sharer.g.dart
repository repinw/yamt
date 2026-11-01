// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_export_file_sharer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the export file sharer.

@ProviderFor(dataExportFileSharer)
final dataExportFileSharerProvider = DataExportFileSharerProvider._();

/// Provides the export file sharer.

final class DataExportFileSharerProvider
    extends
        $FunctionalProvider<
          DataExportFileSharer,
          DataExportFileSharer,
          DataExportFileSharer
        >
    with $Provider<DataExportFileSharer> {
  /// Provides the export file sharer.
  DataExportFileSharerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataExportFileSharerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataExportFileSharerHash();

  @$internal
  @override
  $ProviderElement<DataExportFileSharer> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DataExportFileSharer create(Ref ref) {
    return dataExportFileSharer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DataExportFileSharer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DataExportFileSharer>(value),
    );
  }
}

String _$dataExportFileSharerHash() =>
    r'4f594a3f7848c459b48968e2b557b933dd284b6f';
