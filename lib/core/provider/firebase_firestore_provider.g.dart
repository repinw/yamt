// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_firestore_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Returns Firestore instance unless session shutdown is already in progress.

@ProviderFor(firebaseFirestore)
final firebaseFirestoreProvider = FirebaseFirestoreProvider._();

/// Returns Firestore instance unless session shutdown is already in progress.

final class FirebaseFirestoreProvider
    extends
        $FunctionalProvider<
          FirebaseFirestore?,
          FirebaseFirestore?,
          FirebaseFirestore?
        >
    with $Provider<FirebaseFirestore?> {
  /// Returns Firestore instance unless session shutdown is already in progress.
  FirebaseFirestoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseFirestoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseFirestoreHash();

  @$internal
  @override
  $ProviderElement<FirebaseFirestore?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseFirestore? create(Ref ref) {
    return firebaseFirestore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFirestore? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFirestore?>(value),
    );
  }
}

String _$firebaseFirestoreHash() => r'87e0af104ec5815574b762f717d7943188c6b6aa';
