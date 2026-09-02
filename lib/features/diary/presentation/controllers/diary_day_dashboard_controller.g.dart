// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_day_dashboard_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads and caches the render-ready diary dashboard for one day.

@ProviderFor(DiaryDayDashboardController)
final diaryDayDashboardControllerProvider =
    DiaryDayDashboardControllerFamily._();

/// Loads and caches the render-ready diary dashboard for one day.
final class DiaryDayDashboardControllerProvider
    extends
        $NotifierProvider<DiaryDayDashboardController, DiaryDayDashboardState> {
  /// Loads and caches the render-ready diary dashboard for one day.
  DiaryDayDashboardControllerProvider._({
    required DiaryDayDashboardControllerFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryDayDashboardControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryDayDashboardControllerHash();

  @override
  String toString() {
    return r'diaryDayDashboardControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DiaryDayDashboardController create() => DiaryDayDashboardController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryDayDashboardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryDayDashboardState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryDayDashboardControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryDayDashboardControllerHash() =>
    r'95c17945a6bdfa18b0dfb64735aa0a32468eb33d';

/// Loads and caches the render-ready diary dashboard for one day.

final class DiaryDayDashboardControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          DiaryDayDashboardController,
          DiaryDayDashboardState,
          DiaryDayDashboardState,
          DiaryDayDashboardState,
          DateTime
        > {
  DiaryDayDashboardControllerFamily._()
    : super(
        retry: null,
        name: r'diaryDayDashboardControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads and caches the render-ready diary dashboard for one day.

  DiaryDayDashboardControllerProvider call(DateTime selectedDay) =>
      DiaryDayDashboardControllerProvider._(argument: selectedDay, from: this);

  @override
  String toString() => r'diaryDayDashboardControllerProvider';
}

/// Loads and caches the render-ready diary dashboard for one day.

abstract class _$DiaryDayDashboardController
    extends $Notifier<DiaryDayDashboardState> {
  late final _$args = ref.$arg as DateTime;
  DateTime get selectedDay => _$args;

  DiaryDayDashboardState build(DateTime selectedDay);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<DiaryDayDashboardState, DiaryDayDashboardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DiaryDayDashboardState, DiaryDayDashboardState>,
              DiaryDayDashboardState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
