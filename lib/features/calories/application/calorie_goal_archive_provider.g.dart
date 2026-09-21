// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_archive_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Goal cycles displayed by the Calories goal archive.

@ProviderFor(calorieGoalArchive)
final calorieGoalArchiveProvider = CalorieGoalArchiveProvider._();

/// Goal cycles displayed by the Calories goal archive.

final class CalorieGoalArchiveProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TdeeAnalyticsGoalCycle>>,
          List<TdeeAnalyticsGoalCycle>,
          FutureOr<List<TdeeAnalyticsGoalCycle>>
        >
    with
        $FutureModifier<List<TdeeAnalyticsGoalCycle>>,
        $FutureProvider<List<TdeeAnalyticsGoalCycle>> {
  /// Goal cycles displayed by the Calories goal archive.
  CalorieGoalArchiveProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieGoalArchiveProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieGoalArchiveHash();

  @$internal
  @override
  $FutureProviderElement<List<TdeeAnalyticsGoalCycle>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TdeeAnalyticsGoalCycle>> create(Ref ref) {
    return calorieGoalArchive(ref);
  }
}

String _$calorieGoalArchiveHash() =>
    r'befb6ff0e5c2d25e9050d16f371e3d4528430230';
