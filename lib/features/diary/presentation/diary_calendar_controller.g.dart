// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_calendar_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the current clock for diary calendar state.

@ProviderFor(diaryCalendarNow)
final diaryCalendarNowProvider = DiaryCalendarNowProvider._();

/// Provides the current clock for diary calendar state.

final class DiaryCalendarNowProvider
    extends
        $FunctionalProvider<
          DateTime Function(),
          DateTime Function(),
          DateTime Function()
        >
    with $Provider<DateTime Function()> {
  /// Provides the current clock for diary calendar state.
  DiaryCalendarNowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryCalendarNowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryCalendarNowHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return diaryCalendarNow(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime Function()>(value),
    );
  }
}

String _$diaryCalendarNowHash() => r'0a95f8fa4884f2d9d20836971fb6f57a092fe245';

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
        isAutoDispose: false,
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
    r'39782407bddd7f2a15bafe024ad8023e4425fbf0';

/// Stores the diary calendar selection shared by the shell app bar and page.

abstract class _$DiaryCalendarController extends $Notifier<DiaryCalendarState> {
  DiaryCalendarState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DiaryCalendarState, DiaryCalendarState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DiaryCalendarState, DiaryCalendarState>,
              DiaryCalendarState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
