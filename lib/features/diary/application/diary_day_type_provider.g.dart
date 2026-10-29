// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_day_type_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Day type of [day], or `null` while no calorie goal exists.

@ProviderFor(diaryDayTypeStatus)
final diaryDayTypeStatusProvider = DiaryDayTypeStatusFamily._();

/// Day type of [day], or `null` while no calorie goal exists.

final class DiaryDayTypeStatusProvider
    extends
        $FunctionalProvider<
          DiaryDayTypeStatus?,
          DiaryDayTypeStatus?,
          DiaryDayTypeStatus?
        >
    with $Provider<DiaryDayTypeStatus?> {
  /// Day type of [day], or `null` while no calorie goal exists.
  DiaryDayTypeStatusProvider._({
    required DiaryDayTypeStatusFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryDayTypeStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryDayTypeStatusHash();

  @override
  String toString() {
    return r'diaryDayTypeStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<DiaryDayTypeStatus?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryDayTypeStatus? create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryDayTypeStatus(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryDayTypeStatus? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryDayTypeStatus?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryDayTypeStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryDayTypeStatusHash() =>
    r'eab41ac6d9c7988be2b70ffba970244bbcf5ed0b';

/// Day type of [day], or `null` while no calorie goal exists.

final class DiaryDayTypeStatusFamily extends $Family
    with $FunctionalFamilyOverride<DiaryDayTypeStatus?, DateTime> {
  DiaryDayTypeStatusFamily._()
    : super(
        retry: null,
        name: r'diaryDayTypeStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Day type of [day], or `null` while no calorie goal exists.

  DiaryDayTypeStatusProvider call(DateTime day) =>
      DiaryDayTypeStatusProvider._(argument: day, from: this);

  @override
  String toString() => r'diaryDayTypeStatusProvider';
}
