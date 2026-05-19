// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_entry_post_persist_hook.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The calorie entry post persist hook provider.

@ProviderFor(calorieEntryPostPersistHook)
final calorieEntryPostPersistHookProvider =
    CalorieEntryPostPersistHookProvider._();

/// The calorie entry post persist hook provider.

final class CalorieEntryPostPersistHookProvider
    extends
        $FunctionalProvider<
          CalorieEntryPostPersistHook,
          CalorieEntryPostPersistHook,
          CalorieEntryPostPersistHook
        >
    with $Provider<CalorieEntryPostPersistHook> {
  /// The calorie entry post persist hook provider.
  CalorieEntryPostPersistHookProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieEntryPostPersistHookProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieEntryPostPersistHookHash();

  @$internal
  @override
  $ProviderElement<CalorieEntryPostPersistHook> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieEntryPostPersistHook create(Ref ref) {
    return calorieEntryPostPersistHook(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieEntryPostPersistHook value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieEntryPostPersistHook>(value),
    );
  }
}

String _$calorieEntryPostPersistHookHash() =>
    r'b50c21d19df9622990630ff6077ab1ca40127a86';
