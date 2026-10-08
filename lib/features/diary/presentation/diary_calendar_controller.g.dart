// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_calendar_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Selectable range for the current diary calendar state.

@ProviderFor(diaryCalendarBounds)
final diaryCalendarBoundsProvider = DiaryCalendarBoundsProvider._();

/// Selectable range for the current diary calendar state.

final class DiaryCalendarBoundsProvider
    extends
        $FunctionalProvider<
          DiaryCalendarBounds,
          DiaryCalendarBounds,
          DiaryCalendarBounds
        >
    with $Provider<DiaryCalendarBounds> {
  /// Selectable range for the current diary calendar state.
  DiaryCalendarBoundsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryCalendarBoundsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryCalendarBoundsHash();

  @$internal
  @override
  $ProviderElement<DiaryCalendarBounds> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryCalendarBounds create(Ref ref) {
    return diaryCalendarBounds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryCalendarBounds value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryCalendarBounds>(value),
    );
  }
}

String _$diaryCalendarBoundsHash() =>
    r'd48cb9488420b55ced5ba0cb68ed5ec2778ec7e9';

/// Stores the diary calendar selection shared by the shell app bar and page.

@ProviderFor(DiaryCalendarController)
final diaryCalendarControllerProvider = DiaryCalendarControllerProvider._();

/// Stores the diary calendar selection shared by the shell app bar and page.
final class DiaryCalendarControllerProvider
    extends $NotifierProvider<DiaryCalendarController, DiaryCalendarState> {
  /// Stores the diary calendar selection shared by the shell app bar and page.
  DiaryCalendarControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryCalendarControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryCalendarControllerHash();

  @$internal
  @override
  DiaryCalendarController create() => DiaryCalendarController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryCalendarState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryCalendarState>(value),
    );
  }
}

String _$diaryCalendarControllerHash() =>
    r'3d6caaf27110e029e1271bfa74a82cbed5f75d32';

/// Stores the diary calendar selection shared by the shell app bar and page.

abstract class _$DiaryCalendarController extends $Notifier<DiaryCalendarState> {
  DiaryCalendarState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DiaryCalendarState, DiaryCalendarState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DiaryCalendarState, DiaryCalendarState>,
              DiaryCalendarState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
