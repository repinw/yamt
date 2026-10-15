// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_weekly_checkin_photos_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The photos of [pose] that the check-in sheet of [windowStart] and
/// [preview] (see [DiaryWeeklyCheckInSheetController]) compares: the first
/// since the goal start, a middle one, and today's. A photo shows its typed
/// weight, else the weight of its day.

@ProviderFor(diaryWeeklyCheckInPhotos)
final diaryWeeklyCheckInPhotosProvider = DiaryWeeklyCheckInPhotosFamily._();

/// The photos of [pose] that the check-in sheet of [windowStart] and
/// [preview] (see [DiaryWeeklyCheckInSheetController]) compares: the first
/// since the goal start, a middle one, and today's. A photo shows its typed
/// weight, else the weight of its day.

final class DiaryWeeklyCheckInPhotosProvider
    extends
        $FunctionalProvider<
          AsyncValue<
            ({
              DiaryWeeklyCheckInPhoto? first,
              DiaryWeeklyCheckInPhoto? middle,
              DiaryWeeklyCheckInPhoto? today,
            })
          >,
          ({
            DiaryWeeklyCheckInPhoto? first,
            DiaryWeeklyCheckInPhoto? middle,
            DiaryWeeklyCheckInPhoto? today,
          }),
          FutureOr<
            ({
              DiaryWeeklyCheckInPhoto? first,
              DiaryWeeklyCheckInPhoto? middle,
              DiaryWeeklyCheckInPhoto? today,
            })
          >
        >
    with
        $FutureModifier<
          ({
            DiaryWeeklyCheckInPhoto? first,
            DiaryWeeklyCheckInPhoto? middle,
            DiaryWeeklyCheckInPhoto? today,
          })
        >,
        $FutureProvider<
          ({
            DiaryWeeklyCheckInPhoto? first,
            DiaryWeeklyCheckInPhoto? middle,
            DiaryWeeklyCheckInPhoto? today,
          })
        > {
  /// The photos of [pose] that the check-in sheet of [windowStart] and
  /// [preview] (see [DiaryWeeklyCheckInSheetController]) compares: the first
  /// since the goal start, a middle one, and today's. A photo shows its typed
  /// weight, else the weight of its day.
  DiaryWeeklyCheckInPhotosProvider._({
    required DiaryWeeklyCheckInPhotosFamily super.from,
    required (
      ProgressPhotoPose,
      DateTime, {
      DateTime? windowStart,
      bool preview,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'diaryWeeklyCheckInPhotosProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryWeeklyCheckInPhotosHash();

  @override
  String toString() {
    return r'diaryWeeklyCheckInPhotosProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<
    ({
      DiaryWeeklyCheckInPhoto? first,
      DiaryWeeklyCheckInPhoto? middle,
      DiaryWeeklyCheckInPhoto? today,
    })
  >
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<
    ({
      DiaryWeeklyCheckInPhoto? first,
      DiaryWeeklyCheckInPhoto? middle,
      DiaryWeeklyCheckInPhoto? today,
    })
  >
  create(Ref ref) {
    final argument =
        this.argument
            as (
              ProgressPhotoPose,
              DateTime, {
              DateTime? windowStart,
              bool preview,
            });
    return diaryWeeklyCheckInPhotos(
      ref,
      argument.$1,
      argument.$2,
      windowStart: argument.windowStart,
      preview: argument.preview,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryWeeklyCheckInPhotosProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryWeeklyCheckInPhotosHash() =>
    r'3f080e77d8200c20a1dc41b5f78ac427dc93ddb6';

/// The photos of [pose] that the check-in sheet of [windowStart] and
/// [preview] (see [DiaryWeeklyCheckInSheetController]) compares: the first
/// since the goal start, a middle one, and today's. A photo shows its typed
/// weight, else the weight of its day.

final class DiaryWeeklyCheckInPhotosFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<
            ({
              DiaryWeeklyCheckInPhoto? first,
              DiaryWeeklyCheckInPhoto? middle,
              DiaryWeeklyCheckInPhoto? today,
            })
          >,
          (ProgressPhotoPose, DateTime, {DateTime? windowStart, bool preview})
        > {
  DiaryWeeklyCheckInPhotosFamily._()
    : super(
        retry: null,
        name: r'diaryWeeklyCheckInPhotosProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The photos of [pose] that the check-in sheet of [windowStart] and
  /// [preview] (see [DiaryWeeklyCheckInSheetController]) compares: the first
  /// since the goal start, a middle one, and today's. A photo shows its typed
  /// weight, else the weight of its day.

  DiaryWeeklyCheckInPhotosProvider call(
    ProgressPhotoPose pose,
    DateTime today, {
    required DateTime? windowStart,
    required bool preview,
  }) => DiaryWeeklyCheckInPhotosProvider._(
    argument: (pose, today, windowStart: windowStart, preview: preview),
    from: this,
  );

  @override
  String toString() => r'diaryWeeklyCheckInPhotosProvider';
}
