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
    r'cb85ada94c997a10f4447f25f2638ef56f84c15c';

/// Controller managing save, delete, and pending inventory cleanup for
/// calorie entry editor.

abstract class _$CalorieEntryEditorController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
