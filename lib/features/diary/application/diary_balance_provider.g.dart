// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_balance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The kcal budget of [day] as the balance card shows it, with carryover
/// and training days, from the day's week overview alone; null on a pause
/// day. Cheaper than the day's whole dashboard, which also reads the
/// entries and plans, saves a cache and refreshes after every change.

@ProviderFor(diaryDayBudgetKcal)
final diaryDayBudgetKcalProvider = DiaryDayBudgetKcalFamily._();

/// The kcal budget of [day] as the balance card shows it, with carryover
/// and training days, from the day's week overview alone; null on a pause
/// day. Cheaper than the day's whole dashboard, which also reads the
/// entries and plans, saves a cache and refreshes after every change.

final class DiaryDayBudgetKcalProvider
    extends $FunctionalProvider<AsyncValue<double?>, double?, FutureOr<double?>>
    with $FutureModifier<double?>, $FutureProvider<double?> {
  /// The kcal budget of [day] as the balance card shows it, with carryover
  /// and training days, from the day's week overview alone; null on a pause
  /// day. Cheaper than the day's whole dashboard, which also reads the
  /// entries and plans, saves a cache and refreshes after every change.
  DiaryDayBudgetKcalProvider._({
    required DiaryDayBudgetKcalFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryDayBudgetKcalProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryDayBudgetKcalHash();

  @override
  String toString() {
    return r'diaryDayBudgetKcalProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<double?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double?> create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryDayBudgetKcal(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryDayBudgetKcalProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryDayBudgetKcalHash() =>
    r'9993eff384a4b71346737400f2d152d0c1179b2f';

/// The kcal budget of [day] as the balance card shows it, with carryover
/// and training days, from the day's week overview alone; null on a pause
/// day. Cheaper than the day's whole dashboard, which also reads the
/// entries and plans, saves a cache and refreshes after every change.

final class DiaryDayBudgetKcalFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<double?>, DateTime> {
  DiaryDayBudgetKcalFamily._()
    : super(
        retry: null,
        name: r'diaryDayBudgetKcalProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The kcal budget of [day] as the balance card shows it, with carryover
  /// and training days, from the day's week overview alone; null on a pause
  /// day. Cheaper than the day's whole dashboard, which also reads the
  /// entries and plans, saves a cache and refreshes after every change.

  DiaryDayBudgetKcalProvider call(DateTime day) =>
      DiaryDayBudgetKcalProvider._(argument: day, from: this);

  @override
  String toString() => r'diaryDayBudgetKcalProvider';
}

/// Actions needed by diary balance presentation widgets.

@ProviderFor(diaryBalanceActions)
final diaryBalanceActionsProvider = DiaryBalanceActionsProvider._();

/// Actions needed by diary balance presentation widgets.

final class DiaryBalanceActionsProvider
    extends
        $FunctionalProvider<
          DiaryBalanceActions,
          DiaryBalanceActions,
          DiaryBalanceActions
        >
    with $Provider<DiaryBalanceActions> {
  /// Actions needed by diary balance presentation widgets.
  DiaryBalanceActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryBalanceActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryBalanceActionsHash();

  @$internal
  @override
  $ProviderElement<DiaryBalanceActions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryBalanceActions create(Ref ref) {
    return diaryBalanceActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryBalanceActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryBalanceActions>(value),
    );
  }
}

String _$diaryBalanceActionsHash() =>
    r'a01bd39a2754977b7113fe7d4d12d814abcf325e';
