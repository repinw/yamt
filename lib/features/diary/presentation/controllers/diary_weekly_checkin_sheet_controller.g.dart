// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_weekly_checkin_sheet_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the step and the choices of the weekly check-in sheet.
///
/// One controller per check-in window (`windowStart`). With `preview`, it
/// plans the latest completed window for the debug preview instead of the
/// pending one.

@ProviderFor(DiaryWeeklyCheckInSheetController)
final diaryWeeklyCheckInSheetControllerProvider =
    DiaryWeeklyCheckInSheetControllerFamily._();

/// Holds the step and the choices of the weekly check-in sheet.
///
/// One controller per check-in window (`windowStart`). With `preview`, it
/// plans the latest completed window for the debug preview instead of the
/// pending one.
final class DiaryWeeklyCheckInSheetControllerProvider
    extends
        $AsyncNotifierProvider<
          DiaryWeeklyCheckInSheetController,
          DiaryWeeklyCheckInSheetState?
        > {
  /// Holds the step and the choices of the weekly check-in sheet.
  ///
  /// One controller per check-in window (`windowStart`). With `preview`, it
  /// plans the latest completed window for the debug preview instead of the
  /// pending one.
  DiaryWeeklyCheckInSheetControllerProvider._({
    required DiaryWeeklyCheckInSheetControllerFamily super.from,
    required ({DateTime? windowStart, bool preview}) super.argument,
  }) : super(
         retry: null,
         name: r'diaryWeeklyCheckInSheetControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$diaryWeeklyCheckInSheetControllerHash();

  @override
  String toString() {
    return r'diaryWeeklyCheckInSheetControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  DiaryWeeklyCheckInSheetController create() =>
      DiaryWeeklyCheckInSheetController();

  @override
  bool operator ==(Object other) {
    return other is DiaryWeeklyCheckInSheetControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryWeeklyCheckInSheetControllerHash() =>
    r'52e08bd3391e8992abff364cb8acc66268f482ee';

/// Holds the step and the choices of the weekly check-in sheet.
///
/// One controller per check-in window (`windowStart`). With `preview`, it
/// plans the latest completed window for the debug preview instead of the
/// pending one.

final class DiaryWeeklyCheckInSheetControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          DiaryWeeklyCheckInSheetController,
          AsyncValue<DiaryWeeklyCheckInSheetState?>,
          DiaryWeeklyCheckInSheetState?,
          FutureOr<DiaryWeeklyCheckInSheetState?>,
          ({DateTime? windowStart, bool preview})
        > {
  DiaryWeeklyCheckInSheetControllerFamily._()
    : super(
        retry: null,
        name: r'diaryWeeklyCheckInSheetControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Holds the step and the choices of the weekly check-in sheet.
  ///
  /// One controller per check-in window (`windowStart`). With `preview`, it
  /// plans the latest completed window for the debug preview instead of the
  /// pending one.

  DiaryWeeklyCheckInSheetControllerProvider call({
    required DateTime? windowStart,
    bool preview = false,
  }) => DiaryWeeklyCheckInSheetControllerProvider._(
    argument: (windowStart: windowStart, preview: preview),
    from: this,
  );

  @override
  String toString() => r'diaryWeeklyCheckInSheetControllerProvider';
}

/// Holds the step and the choices of the weekly check-in sheet.
///
/// One controller per check-in window (`windowStart`). With `preview`, it
/// plans the latest completed window for the debug preview instead of the
/// pending one.

abstract class _$DiaryWeeklyCheckInSheetController
    extends $AsyncNotifier<DiaryWeeklyCheckInSheetState?> {
  late final _$args = ref.$arg as ({DateTime? windowStart, bool preview});
  DateTime? get windowStart => _$args.windowStart;
  bool get preview => _$args.preview;

  FutureOr<DiaryWeeklyCheckInSheetState?> build({
    required DateTime? windowStart,
    bool preview = false,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<DiaryWeeklyCheckInSheetState?>,
              DiaryWeeklyCheckInSheetState?
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<DiaryWeeklyCheckInSheetState?>,
                DiaryWeeklyCheckInSheetState?
              >,
              AsyncValue<DiaryWeeklyCheckInSheetState?>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(windowStart: _$args.windowStart, preview: _$args.preview),
    );
  }
}
