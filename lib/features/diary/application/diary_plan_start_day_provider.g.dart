// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_plan_start_day_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// First day of the user's plan, or `null` while no plan exists.

@ProviderFor(diaryPlanStartDay)
final diaryPlanStartDayProvider = DiaryPlanStartDayProvider._();

/// First day of the user's plan, or `null` while no plan exists.

final class DiaryPlanStartDayProvider
    extends $FunctionalProvider<DateTime?, DateTime?, DateTime?>
    with $Provider<DateTime?> {
  /// First day of the user's plan, or `null` while no plan exists.
  DiaryPlanStartDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryPlanStartDayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryPlanStartDayHash();

  @$internal
  @override
  $ProviderElement<DateTime?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime? create(Ref ref) {
    return diaryPlanStartDay(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$diaryPlanStartDayHash() => r'78dac2181711ddaa40058b86f91f85fde0662bca';
