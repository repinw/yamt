// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_plan_details_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller of the details page of the plan [planId] on [planDay]: holds
/// the day, meal, amount and portions the user picks until they save. Null
/// once the plan is gone from its day, for example eaten.

@ProviderFor(DiaryPlanDetailsController)
final diaryPlanDetailsControllerProvider = DiaryPlanDetailsControllerFamily._();

/// Controller of the details page of the plan [planId] on [planDay]: holds
/// the day, meal, amount and portions the user picks until they save. Null
/// once the plan is gone from its day, for example eaten.
final class DiaryPlanDetailsControllerProvider
    extends
        $NotifierProvider<DiaryPlanDetailsController, DiaryPlanDetailsState?> {
  /// Controller of the details page of the plan [planId] on [planDay]: holds
  /// the day, meal, amount and portions the user picks until they save. Null
  /// once the plan is gone from its day, for example eaten.
  DiaryPlanDetailsControllerProvider._({
    required DiaryPlanDetailsControllerFamily super.from,
    required (String, DateTime, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'diaryPlanDetailsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryPlanDetailsControllerHash();

  @override
  String toString() {
    return r'diaryPlanDetailsControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  DiaryPlanDetailsController create() => DiaryPlanDetailsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryPlanDetailsState? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryPlanDetailsState?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryPlanDetailsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryPlanDetailsControllerHash() =>
    r'038317a1e38a1851a7eedd9501a475480df23330';

/// Controller of the details page of the plan [planId] on [planDay]: holds
/// the day, meal, amount and portions the user picks until they save. Null
/// once the plan is gone from its day, for example eaten.

final class DiaryPlanDetailsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          DiaryPlanDetailsController,
          DiaryPlanDetailsState?,
          DiaryPlanDetailsState?,
          DiaryPlanDetailsState?,
          (String, DateTime, DateTime)
        > {
  DiaryPlanDetailsControllerFamily._()
    : super(
        retry: null,
        name: r'diaryPlanDetailsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Controller of the details page of the plan [planId] on [planDay]: holds
  /// the day, meal, amount and portions the user picks until they save. Null
  /// once the plan is gone from its day, for example eaten.

  DiaryPlanDetailsControllerProvider call(
    String planId,
    DateTime planDay,
    DateTime today,
  ) => DiaryPlanDetailsControllerProvider._(
    argument: (planId, planDay, today),
    from: this,
  );

  @override
  String toString() => r'diaryPlanDetailsControllerProvider';
}

/// Controller of the details page of the plan [planId] on [planDay]: holds
/// the day, meal, amount and portions the user picks until they save. Null
/// once the plan is gone from its day, for example eaten.

abstract class _$DiaryPlanDetailsController
    extends $Notifier<DiaryPlanDetailsState?> {
  late final _$args = ref.$arg as (String, DateTime, DateTime);
  String get planId => _$args.$1;
  DateTime get planDay => _$args.$2;
  DateTime get today => _$args.$3;

  DiaryPlanDetailsState? build(String planId, DateTime planDay, DateTime today);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<DiaryPlanDetailsState?, DiaryPlanDetailsState?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DiaryPlanDetailsState?, DiaryPlanDetailsState?>,
              DiaryPlanDetailsState?,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(_$args.$1, _$args.$2, _$args.$3),
    );
  }
}
