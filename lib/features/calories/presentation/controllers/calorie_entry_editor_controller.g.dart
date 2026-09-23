// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_entry_editor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller managing save, delete, and pending inventory cleanup for
/// calorie entry editor.

@ProviderFor(CalorieEntryEditorController)
final calorieEntryEditorControllerProvider =
    CalorieEntryEditorControllerProvider._();

/// Controller managing save, delete, and pending inventory cleanup for
/// calorie entry editor.
final class CalorieEntryEditorControllerProvider
    extends $NotifierProvider<CalorieEntryEditorController, bool> {
  /// Controller managing save, delete, and pending inventory cleanup for
  /// calorie entry editor.
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
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$calorieEntryEditorControllerHash() =>
    r'1bd9d6666e90bf6fb70d377be50235dc7d32c72e';

/// Controller managing save, delete, and pending inventory cleanup for
/// calorie entry editor.

abstract class _$CalorieEntryEditorController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
