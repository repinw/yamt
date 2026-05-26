// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_balance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides source data for the diary balance card.

@ProviderFor(diaryBalanceSource)
final diaryBalanceSourceProvider = DiaryBalanceSourceFamily._();

/// Provides source data for the diary balance card.

final class DiaryBalanceSourceProvider
    extends
        $FunctionalProvider<
          AsyncValue<DiaryBalanceSource>,
          DiaryBalanceSource,
          FutureOr<DiaryBalanceSource>
        >
    with
        $FutureModifier<DiaryBalanceSource>,
        $FutureProvider<DiaryBalanceSource> {
  /// Provides source data for the diary balance card.
  DiaryBalanceSourceProvider._({
    required DiaryBalanceSourceFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryBalanceSourceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryBalanceSourceHash();

  @override
  String toString() {
    return r'diaryBalanceSourceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DiaryBalanceSource> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DiaryBalanceSource> create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryBalanceSource(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryBalanceSourceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryBalanceSourceHash() =>
    r'1519977bb8da44b7736cde8db1e8fc395ab62d23';

/// Provides source data for the diary balance card.

final class DiaryBalanceSourceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DiaryBalanceSource>, DateTime> {
  DiaryBalanceSourceFamily._()
    : super(
        retry: null,
        name: r'diaryBalanceSourceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides source data for the diary balance card.

  DiaryBalanceSourceProvider call(DateTime selectedDay) =>
      DiaryBalanceSourceProvider._(argument: selectedDay, from: this);

  @override
  String toString() => r'diaryBalanceSourceProvider';
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
    r'b88a067541e3952336d58503b13600894b9ccda4';
