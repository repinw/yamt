// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_balance_card_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The resolved balance of [day], read by the balance card, the macro strip
/// and the home widget, so all three show the same numbers and move to the
/// new day together. `null` while the day's dashboard has not loaded yet.
///
/// Lives in `presentation/` because it derives from the dashboard
/// controller's state.

@ProviderFor(diaryBalanceCard)
final diaryBalanceCardProvider = DiaryBalanceCardFamily._();

/// The resolved balance of [day], read by the balance card, the macro strip
/// and the home widget, so all three show the same numbers and move to the
/// new day together. `null` while the day's dashboard has not loaded yet.
///
/// Lives in `presentation/` because it derives from the dashboard
/// controller's state.

final class DiaryBalanceCardProvider
    extends
        $FunctionalProvider<
          DiaryBalanceCardData?,
          DiaryBalanceCardData?,
          DiaryBalanceCardData?
        >
    with $Provider<DiaryBalanceCardData?> {
  /// The resolved balance of [day], read by the balance card, the macro strip
  /// and the home widget, so all three show the same numbers and move to the
  /// new day together. `null` while the day's dashboard has not loaded yet.
  ///
  /// Lives in `presentation/` because it derives from the dashboard
  /// controller's state.
  DiaryBalanceCardProvider._({
    required DiaryBalanceCardFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryBalanceCardProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryBalanceCardHash();

  @override
  String toString() {
    return r'diaryBalanceCardProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<DiaryBalanceCardData?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryBalanceCardData? create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryBalanceCard(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryBalanceCardData? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryBalanceCardData?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryBalanceCardProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryBalanceCardHash() => r'e422579d44984b4119c06f15dce362507e04b0c9';

/// The resolved balance of [day], read by the balance card, the macro strip
/// and the home widget, so all three show the same numbers and move to the
/// new day together. `null` while the day's dashboard has not loaded yet.
///
/// Lives in `presentation/` because it derives from the dashboard
/// controller's state.

final class DiaryBalanceCardFamily extends $Family
    with $FunctionalFamilyOverride<DiaryBalanceCardData?, DateTime> {
  DiaryBalanceCardFamily._()
    : super(
        retry: null,
        name: r'diaryBalanceCardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The resolved balance of [day], read by the balance card, the macro strip
  /// and the home widget, so all three show the same numbers and move to the
  /// new day together. `null` while the day's dashboard has not loaded yet.
  ///
  /// Lives in `presentation/` because it derives from the dashboard
  /// controller's state.

  DiaryBalanceCardProvider call(DateTime day) =>
      DiaryBalanceCardProvider._(argument: day, from: this);

  @override
  String toString() => r'diaryBalanceCardProvider';
}
