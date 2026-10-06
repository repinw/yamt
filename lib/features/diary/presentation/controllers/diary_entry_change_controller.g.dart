// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_entry_change_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Saves, changes, and deletes logged diary entries. An entry that took
/// stock moves it with a changed amount and can give it back on delete.

@ProviderFor(DiaryEntryChangeController)
final diaryEntryChangeControllerProvider =
    DiaryEntryChangeControllerProvider._();

/// Saves, changes, and deletes logged diary entries. An entry that took
/// stock moves it with a changed amount and can give it back on delete.
final class DiaryEntryChangeControllerProvider
    extends $AsyncNotifierProvider<DiaryEntryChangeController, void> {
  /// Saves, changes, and deletes logged diary entries. An entry that took
  /// stock moves it with a changed amount and can give it back on delete.
  DiaryEntryChangeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryEntryChangeControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryEntryChangeControllerHash();

  @$internal
  @override
  DiaryEntryChangeController create() => DiaryEntryChangeController();
}

String _$diaryEntryChangeControllerHash() =>
    r'e88f113680c8596da7e7495986e4c1f5885f3355';

/// Saves, changes, and deletes logged diary entries. An entry that took
/// stock moves it with a changed amount and can give it back on delete.

abstract class _$DiaryEntryChangeController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
