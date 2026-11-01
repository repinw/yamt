// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_pace_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The share of the day's kcal due by now on [day], from the user's parts
/// of the day and meal times; null while the marker is off and on any day
/// but today. It moves on with every minute.

@ProviderFor(diaryPaceShare)
final diaryPaceShareProvider = DiaryPaceShareFamily._();

/// The share of the day's kcal due by now on [day], from the user's parts
/// of the day and meal times; null while the marker is off and on any day
/// but today. It moves on with every minute.

final class DiaryPaceShareProvider
    extends $FunctionalProvider<double?, double?, double?>
    with $Provider<double?> {
  /// The share of the day's kcal due by now on [day], from the user's parts
  /// of the day and meal times; null while the marker is off and on any day
  /// but today. It moves on with every minute.
  DiaryPaceShareProvider._({
    required DiaryPaceShareFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryPaceShareProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryPaceShareHash();

  @override
  String toString() {
    return r'diaryPaceShareProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<double?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double? create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryPaceShare(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryPaceShareProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryPaceShareHash() => r'd7e3d6a9eada5586e3d5cf7b0e6576dc37357ac0';

/// The share of the day's kcal due by now on [day], from the user's parts
/// of the day and meal times; null while the marker is off and on any day
/// but today. It moves on with every minute.

final class DiaryPaceShareFamily extends $Family
    with $FunctionalFamilyOverride<double?, DateTime> {
  DiaryPaceShareFamily._()
    : super(
        retry: null,
        name: r'diaryPaceShareProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The share of the day's kcal due by now on [day], from the user's parts
  /// of the day and meal times; null while the marker is off and on any day
  /// but today. It moves on with every minute.

  DiaryPaceShareProvider call(DateTime day) =>
      DiaryPaceShareProvider._(argument: day, from: this);

  @override
  String toString() => r'diaryPaceShareProvider';
}
