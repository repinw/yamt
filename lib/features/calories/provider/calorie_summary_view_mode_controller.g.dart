// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_summary_view_mode_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Defines calorie summary view mode controller.

@ProviderFor(CalorieSummaryViewModeController)
final calorieSummaryViewModeControllerProvider =
    CalorieSummaryViewModeControllerProvider._();

/// Defines calorie summary view mode controller.
final class CalorieSummaryViewModeControllerProvider
    extends
        $NotifierProvider<
          CalorieSummaryViewModeController,
          CalorieSummaryViewMode
        > {
  /// Defines calorie summary view mode controller.
  CalorieSummaryViewModeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieSummaryViewModeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieSummaryViewModeControllerHash();

  @$internal
  @override
  CalorieSummaryViewModeController create() =>
      CalorieSummaryViewModeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieSummaryViewMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieSummaryViewMode>(value),
    );
  }
}

String _$calorieSummaryViewModeControllerHash() =>
    r'9bf062ad39c3e9c01484e124ad8a6db15d8edf65';

/// Defines calorie summary view mode controller.

abstract class _$CalorieSummaryViewModeController
    extends $Notifier<CalorieSummaryViewMode> {
  CalorieSummaryViewMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<CalorieSummaryViewMode, CalorieSummaryViewMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalorieSummaryViewMode, CalorieSummaryViewMode>,
              CalorieSummaryViewMode,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
