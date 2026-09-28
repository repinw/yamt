// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_debug_file_exporter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the calorie debug file exporter.

@ProviderFor(calorieDebugFileExporter)
final calorieDebugFileExporterProvider = CalorieDebugFileExporterProvider._();

/// Provides the calorie debug file exporter.

final class CalorieDebugFileExporterProvider
    extends
        $FunctionalProvider<
          CalorieDebugFileExporter,
          CalorieDebugFileExporter,
          CalorieDebugFileExporter
        >
    with $Provider<CalorieDebugFileExporter> {
  /// Provides the calorie debug file exporter.
  CalorieDebugFileExporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieDebugFileExporterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieDebugFileExporterHash();

  @$internal
  @override
  $ProviderElement<CalorieDebugFileExporter> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieDebugFileExporter create(Ref ref) {
    return calorieDebugFileExporter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieDebugFileExporter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieDebugFileExporter>(value),
    );
  }
}

String _$calorieDebugFileExporterHash() =>
    r'c6aeb599309b229919e4ff8f99b9d059ae49be5e';
