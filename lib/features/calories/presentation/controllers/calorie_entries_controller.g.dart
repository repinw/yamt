// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_entries_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Defines calorie entries controller.

@ProviderFor(CalorieEntriesController)
final calorieEntriesControllerProvider = CalorieEntriesControllerProvider._();

/// Defines calorie entries controller.
final class CalorieEntriesControllerProvider
    extends
        $AsyncNotifierProvider<CalorieEntriesController, List<CalorieEntry>> {
  /// Defines calorie entries controller.
  CalorieEntriesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieEntriesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieEntriesControllerHash();

  @$internal
  @override
  CalorieEntriesController create() => CalorieEntriesController();
}

String _$calorieEntriesControllerHash() =>
    r'bcc511033cbb603615f593ea6c79f133fef2132f';

/// Defines calorie entries controller.

abstract class _$CalorieEntriesController
    extends $AsyncNotifier<List<CalorieEntry>> {
  FutureOr<List<CalorieEntry>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<CalorieEntry>>, List<CalorieEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<CalorieEntry>>, List<CalorieEntry>>,
              AsyncValue<List<CalorieEntry>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
