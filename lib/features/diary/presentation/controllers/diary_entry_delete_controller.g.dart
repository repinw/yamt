// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_entry_delete_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Deletes diary entries and undoes the delete. An entry that took stock
/// can give it back to the Vorrat.

@ProviderFor(DiaryEntryDeleteController)
final diaryEntryDeleteControllerProvider =
    DiaryEntryDeleteControllerProvider._();

/// Deletes diary entries and undoes the delete. An entry that took stock
/// can give it back to the Vorrat.
final class DiaryEntryDeleteControllerProvider
    extends $AsyncNotifierProvider<DiaryEntryDeleteController, void> {
  /// Deletes diary entries and undoes the delete. An entry that took stock
  /// can give it back to the Vorrat.
  DiaryEntryDeleteControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryEntryDeleteControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryEntryDeleteControllerHash();

  @$internal
  @override
  DiaryEntryDeleteController create() => DiaryEntryDeleteController();
}

String _$diaryEntryDeleteControllerHash() =>
    r'8bda798c6ac97c7e1c7ee1ee12faa7d2858dfa85';

/// Deletes diary entries and undoes the delete. An entry that took stock
/// can give it back to the Vorrat.

abstract class _$DiaryEntryDeleteController extends $AsyncNotifier<void> {
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
