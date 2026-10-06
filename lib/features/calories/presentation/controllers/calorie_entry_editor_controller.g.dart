// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_entry_editor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller managing save and delete of calorie entries from the diary.

@ProviderFor(CalorieEntryEditorController)
final calorieEntryEditorControllerProvider =
    CalorieEntryEditorControllerProvider._();

/// Controller managing save and delete of calorie entries from the diary.
final class CalorieEntryEditorControllerProvider
    extends $NotifierProvider<CalorieEntryEditorController, void> {
  /// Controller managing save and delete of calorie entries from the diary.
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
    r'201df562e86711ddb0544728b55a2f1f6a2daa77';

/// Controller managing save and delete of calorie entries from the diary.

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
