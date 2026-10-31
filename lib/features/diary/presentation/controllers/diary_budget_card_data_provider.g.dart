// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_budget_card_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The budget card data of the normalized [day], or null while the balance
/// loads. The budget card and the dashboard tiles read it alike, so it is
/// built once per day.

@ProviderFor(diaryBudgetCardData)
final diaryBudgetCardDataProvider = DiaryBudgetCardDataFamily._();

/// The budget card data of the normalized [day], or null while the balance
/// loads. The budget card and the dashboard tiles read it alike, so it is
/// built once per day.

final class DiaryBudgetCardDataProvider
    extends
        $FunctionalProvider<
          DiaryBudgetCardData?,
          DiaryBudgetCardData?,
          DiaryBudgetCardData?
        >
    with $Provider<DiaryBudgetCardData?> {
  /// The budget card data of the normalized [day], or null while the balance
  /// loads. The budget card and the dashboard tiles read it alike, so it is
  /// built once per day.
  DiaryBudgetCardDataProvider._({
    required DiaryBudgetCardDataFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryBudgetCardDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryBudgetCardDataHash();

  @override
  String toString() {
    return r'diaryBudgetCardDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<DiaryBudgetCardData?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryBudgetCardData? create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryBudgetCardData(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryBudgetCardData? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryBudgetCardData?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryBudgetCardDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryBudgetCardDataHash() =>
    r'21df430367c2c0817a7b652d12caf22f5d6cd4c5';

/// The budget card data of the normalized [day], or null while the balance
/// loads. The budget card and the dashboard tiles read it alike, so it is
/// built once per day.

final class DiaryBudgetCardDataFamily extends $Family
    with $FunctionalFamilyOverride<DiaryBudgetCardData?, DateTime> {
  DiaryBudgetCardDataFamily._()
    : super(
        retry: null,
        name: r'diaryBudgetCardDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The budget card data of the normalized [day], or null while the balance
  /// loads. The budget card and the dashboard tiles read it alike, so it is
  /// built once per day.

  DiaryBudgetCardDataProvider call(DateTime day) =>
      DiaryBudgetCardDataProvider._(argument: day, from: this);

  @override
  String toString() => r'diaryBudgetCardDataProvider';
}
