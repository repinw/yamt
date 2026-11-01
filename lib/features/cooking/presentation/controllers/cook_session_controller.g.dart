// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cook_session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds one cooking of the recipe `recipeId` while its page is open.

@ProviderFor(CookSessionController)
final cookSessionControllerProvider = CookSessionControllerFamily._();

/// Holds one cooking of the recipe `recipeId` while its page is open.
final class CookSessionControllerProvider
    extends $NotifierProvider<CookSessionController, CookSession> {
  /// Holds one cooking of the recipe `recipeId` while its page is open.
  CookSessionControllerProvider._({
    required CookSessionControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cookSessionControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cookSessionControllerHash();

  @override
  String toString() {
    return r'cookSessionControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CookSessionController create() => CookSessionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CookSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CookSession>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CookSessionControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cookSessionControllerHash() =>
    r'a28560f79f86c766bca2545609939ed5e4d1119a';

/// Holds one cooking of the recipe `recipeId` while its page is open.

final class CookSessionControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          CookSessionController,
          CookSession,
          CookSession,
          CookSession,
          String
        > {
  CookSessionControllerFamily._()
    : super(
        retry: null,
        name: r'cookSessionControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Holds one cooking of the recipe `recipeId` while its page is open.

  CookSessionControllerProvider call(String recipeId) =>
      CookSessionControllerProvider._(argument: recipeId, from: this);

  @override
  String toString() => r'cookSessionControllerProvider';
}

/// Holds one cooking of the recipe `recipeId` while its page is open.

abstract class _$CookSessionController extends $Notifier<CookSession> {
  late final _$args = ref.$arg as String;
  String get recipeId => _$args;

  CookSession build(String recipeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CookSession, CookSession>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CookSession, CookSession>,
              CookSession,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
