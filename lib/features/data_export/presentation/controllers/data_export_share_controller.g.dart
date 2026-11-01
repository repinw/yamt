// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_export_share_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Writes the export files and shares or saves them.

@ProviderFor(DataExportShareController)
final dataExportShareControllerProvider = DataExportShareControllerProvider._();

/// Writes the export files and shares or saves them.
final class DataExportShareControllerProvider
    extends $AsyncNotifierProvider<DataExportShareController, void> {
  /// Writes the export files and shares or saves them.
  DataExportShareControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataExportShareControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataExportShareControllerHash();

  @$internal
  @override
  DataExportShareController create() => DataExportShareController();
}

String _$dataExportShareControllerHash() =>
    r'6e99cd4c84c01c089ccf87e608764bcff280db44';

/// Writes the export files and shares or saves them.

abstract class _$DataExportShareController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
