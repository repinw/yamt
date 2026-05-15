// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_activity_weight_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides real activity and weight data for the selected diary day.

@ProviderFor(diaryActivityWeightData)
final diaryActivityWeightDataProvider = DiaryActivityWeightDataFamily._();

/// Provides real activity and weight data for the selected diary day.

final class DiaryActivityWeightDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<DiaryActivityWeightData>,
          DiaryActivityWeightData,
          FutureOr<DiaryActivityWeightData>
        >
    with
        $FutureModifier<DiaryActivityWeightData>,
        $FutureProvider<DiaryActivityWeightData> {
  /// Provides real activity and weight data for the selected diary day.
  DiaryActivityWeightDataProvider._({
    required DiaryActivityWeightDataFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryActivityWeightDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryActivityWeightDataHash();

  @override
  String toString() {
    return r'diaryActivityWeightDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DiaryActivityWeightData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DiaryActivityWeightData> create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryActivityWeightData(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryActivityWeightDataProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryActivityWeightDataHash() =>
    r'c14af97c98a9ea243898961a47c0d302e3fa8af7';

/// Provides real activity and weight data for the selected diary day.

final class DiaryActivityWeightDataFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<DiaryActivityWeightData>, DateTime> {
  DiaryActivityWeightDataFamily._()
    : super(
        retry: null,
        name: r'diaryActivityWeightDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides real activity and weight data for the selected diary day.

  DiaryActivityWeightDataProvider call(DateTime day) =>
      DiaryActivityWeightDataProvider._(argument: day, from: this);

  @override
  String toString() => r'diaryActivityWeightDataProvider';
}
