// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_health_connect_action_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolves the Health Connect card state and action.

@ProviderFor(diaryHealthConnectAction)
final diaryHealthConnectActionProvider = DiaryHealthConnectActionFamily._();

/// Resolves the Health Connect card state and action.

final class DiaryHealthConnectActionProvider
    extends
        $FunctionalProvider<
          DiaryHealthConnectActionData,
          DiaryHealthConnectActionData,
          DiaryHealthConnectActionData
        >
    with $Provider<DiaryHealthConnectActionData> {
  /// Resolves the Health Connect card state and action.
  DiaryHealthConnectActionProvider._({
    required DiaryHealthConnectActionFamily super.from,
    required HealthDataAccessState super.argument,
  }) : super(
         retry: null,
         name: r'diaryHealthConnectActionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryHealthConnectActionHash();

  @override
  String toString() {
    return r'diaryHealthConnectActionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<DiaryHealthConnectActionData> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryHealthConnectActionData create(Ref ref) {
    final argument = this.argument as HealthDataAccessState;
    return diaryHealthConnectAction(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryHealthConnectActionData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryHealthConnectActionData>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryHealthConnectActionProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryHealthConnectActionHash() =>
    r'a1177bae99bbad317bede74977efde7f2b4bd8ca';

/// Resolves the Health Connect card state and action.

final class DiaryHealthConnectActionFamily extends $Family
    with
        $FunctionalFamilyOverride<
          DiaryHealthConnectActionData,
          HealthDataAccessState
        > {
  DiaryHealthConnectActionFamily._()
    : super(
        retry: null,
        name: r'diaryHealthConnectActionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Resolves the Health Connect card state and action.

  DiaryHealthConnectActionProvider call(
    HealthDataAccessState fallbackAccessState,
  ) => DiaryHealthConnectActionProvider._(
    argument: fallbackAccessState,
    from: this,
  );

  @override
  String toString() => r'diaryHealthConnectActionProvider';
}
