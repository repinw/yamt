// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_entry_details_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller of the details page of one logged diary entry.
///
/// Holds the entry and the amount typed on the ruler. The page saves
/// changes through the Calories details flow and hands the result back
/// here. The state is null when the entry does not exist.

@ProviderFor(DiaryEntryDetailsController)
final diaryEntryDetailsControllerProvider =
    DiaryEntryDetailsControllerFamily._();

/// Controller of the details page of one logged diary entry.
///
/// Holds the entry and the amount typed on the ruler. The page saves
/// changes through the Calories details flow and hands the result back
/// here. The state is null when the entry does not exist.
final class DiaryEntryDetailsControllerProvider
    extends
        $AsyncNotifierProvider<
          DiaryEntryDetailsController,
          DiaryEntryDetailsState?
        > {
  /// Controller of the details page of one logged diary entry.
  ///
  /// Holds the entry and the amount typed on the ruler. The page saves
  /// changes through the Calories details flow and hands the result back
  /// here. The state is null when the entry does not exist.
  DiaryEntryDetailsControllerProvider._({
    required DiaryEntryDetailsControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'diaryEntryDetailsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryEntryDetailsControllerHash();

  @override
  String toString() {
    return r'diaryEntryDetailsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DiaryEntryDetailsController create() => DiaryEntryDetailsController();

  @override
  bool operator ==(Object other) {
    return other is DiaryEntryDetailsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryEntryDetailsControllerHash() =>
    r'fe5bddca9ca5b8644cb99b371467bbe26a469e41';

/// Controller of the details page of one logged diary entry.
///
/// Holds the entry and the amount typed on the ruler. The page saves
/// changes through the Calories details flow and hands the result back
/// here. The state is null when the entry does not exist.

final class DiaryEntryDetailsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          DiaryEntryDetailsController,
          AsyncValue<DiaryEntryDetailsState?>,
          DiaryEntryDetailsState?,
          FutureOr<DiaryEntryDetailsState?>,
          String
        > {
  DiaryEntryDetailsControllerFamily._()
    : super(
        retry: null,
        name: r'diaryEntryDetailsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Controller of the details page of one logged diary entry.
  ///
  /// Holds the entry and the amount typed on the ruler. The page saves
  /// changes through the Calories details flow and hands the result back
  /// here. The state is null when the entry does not exist.

  DiaryEntryDetailsControllerProvider call(String entryId) =>
      DiaryEntryDetailsControllerProvider._(argument: entryId, from: this);

  @override
  String toString() => r'diaryEntryDetailsControllerProvider';
}

/// Controller of the details page of one logged diary entry.
///
/// Holds the entry and the amount typed on the ruler. The page saves
/// changes through the Calories details flow and hands the result back
/// here. The state is null when the entry does not exist.

abstract class _$DiaryEntryDetailsController
    extends $AsyncNotifier<DiaryEntryDetailsState?> {
  late final _$args = ref.$arg as String;
  String get entryId => _$args;

  FutureOr<DiaryEntryDetailsState?> build(String entryId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<DiaryEntryDetailsState?>,
              DiaryEntryDetailsState?
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<DiaryEntryDetailsState?>,
                DiaryEntryDetailsState?
              >,
              AsyncValue<DiaryEntryDetailsState?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
