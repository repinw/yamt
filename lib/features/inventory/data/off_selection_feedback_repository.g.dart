// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'off_selection_feedback_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Off selection feedback repository.

@ProviderFor(offSelectionFeedbackRepository)
final offSelectionFeedbackRepositoryProvider =
    OffSelectionFeedbackRepositoryProvider._();

/// Off selection feedback repository.

final class OffSelectionFeedbackRepositoryProvider
    extends
        $FunctionalProvider<
          OffSelectionFeedbackRepository,
          OffSelectionFeedbackRepository,
          OffSelectionFeedbackRepository
        >
    with $Provider<OffSelectionFeedbackRepository> {
  /// Off selection feedback repository.
  OffSelectionFeedbackRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offSelectionFeedbackRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offSelectionFeedbackRepositoryHash();

  @$internal
  @override
  $ProviderElement<OffSelectionFeedbackRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OffSelectionFeedbackRepository create(Ref ref) {
    return offSelectionFeedbackRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OffSelectionFeedbackRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OffSelectionFeedbackRepository>(
        value,
      ),
    );
  }
}

String _$offSelectionFeedbackRepositoryHash() =>
    r'48c814520894ea5a7a9e9622bf536c0e4eec4947';
