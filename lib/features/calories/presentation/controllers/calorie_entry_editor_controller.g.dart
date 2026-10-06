// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_entry_editor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Saves, changes, and deletes logged calorie entries for the details page.

@ProviderFor(CalorieEntryEditorController)
final calorieEntryEditorControllerProvider =
    CalorieEntryEditorControllerProvider._();

/// Saves, changes, and deletes logged calorie entries for the details page.
final class CalorieEntryEditorControllerProvider
    extends $NotifierProvider<CalorieEntryEditorController, void> {
  /// Saves, changes, and deletes logged calorie entries for the details page.
  CalorieEntryEditorControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieEntryEditorControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieEntryEditorControllerHash();

  @$internal
  @override
  CalorieEntryEditorController create() => CalorieEntryEditorController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$calorieEntryEditorControllerHash() =>
    r'0743ae1c8cc32ea165251f26ba11398ac42c95c3';

/// Saves, changes, and deletes logged calorie entries for the details page.

abstract class _$CalorieEntryEditorController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
