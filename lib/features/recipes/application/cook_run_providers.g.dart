// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cook_run_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Watches the cook runs of the household, newest first.

@ProviderFor(cookRuns)
final cookRunsProvider = CookRunsProvider._();

/// Watches the cook runs of the household, newest first.

final class CookRunsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CookRun>>,
          List<CookRun>,
          Stream<List<CookRun>>
        >
    with $FutureModifier<List<CookRun>>, $StreamProvider<List<CookRun>> {
  /// Watches the cook runs of the household, newest first.
  CookRunsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookRunsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookRunsHash();

  @$internal
  @override
  $StreamProviderElement<List<CookRun>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CookRun>> create(Ref ref) {
    return cookRuns(ref);
  }
}

String _$cookRunsHash() => r'0fe2c35a0ac33948cf6068c69cceb2e60328411b';

/// The cook run [id], `null` while it does not exist.

@ProviderFor(cookRun)
final cookRunProvider = CookRunFamily._();

/// The cook run [id], `null` while it does not exist.

final class CookRunProvider
    extends
        $FunctionalProvider<AsyncValue<CookRun?>, CookRun?, FutureOr<CookRun?>>
    with $FutureModifier<CookRun?>, $FutureProvider<CookRun?> {
  /// The cook run [id], `null` while it does not exist.
  CookRunProvider._({
    required CookRunFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cookRunProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cookRunHash();

  @override
  String toString() {
    return r'cookRunProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CookRun?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<CookRun?> create(Ref ref) {
    final argument = this.argument as String;
    return cookRun(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CookRunProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cookRunHash() => r'bddc78c9dc8f09babc53233260d97bf112a1edc3';

/// The cook run [id], `null` while it does not exist.

final class CookRunFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CookRun?>, String> {
  CookRunFamily._()
    : super(
        retry: null,
        name: r'cookRunProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The cook run [id], `null` while it does not exist.

  CookRunProvider call(String id) =>
      CookRunProvider._(argument: id, from: this);

  @override
  String toString() => r'cookRunProvider';
}

/// The cook run of the recipe [recipeId], `null` while none runs.

@ProviderFor(recipeCookRun)
final recipeCookRunProvider = RecipeCookRunFamily._();

/// The cook run of the recipe [recipeId], `null` while none runs.

final class RecipeCookRunProvider
    extends
        $FunctionalProvider<AsyncValue<CookRun?>, CookRun?, FutureOr<CookRun?>>
    with $FutureModifier<CookRun?>, $FutureProvider<CookRun?> {
  /// The cook run of the recipe [recipeId], `null` while none runs.
  RecipeCookRunProvider._({
    required RecipeCookRunFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recipeCookRunProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipeCookRunHash();

  @override
  String toString() {
    return r'recipeCookRunProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CookRun?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<CookRun?> create(Ref ref) {
    final argument = this.argument as String;
    return recipeCookRun(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeCookRunProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeCookRunHash() => r'f1b40c8061dcf14bc42596e60233067ab5558b53';

/// The cook run of the recipe [recipeId], `null` while none runs.

final class RecipeCookRunFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CookRun?>, String> {
  RecipeCookRunFamily._()
    : super(
        retry: null,
        name: r'recipeCookRunProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The cook run of the recipe [recipeId], `null` while none runs.

  RecipeCookRunProvider call(String recipeId) =>
      RecipeCookRunProvider._(argument: recipeId, from: this);

  @override
  String toString() => r'recipeCookRunProvider';
}

/// What all cook runs together take from each Vorrat item, by item id.
/// The open run counts here too: the cooking page sums the other runs
/// itself with `reservationsOf` over [cookRuns] without its own id.

@ProviderFor(cookRunReservations)
final cookRunReservationsProvider = CookRunReservationsProvider._();

/// What all cook runs together take from each Vorrat item, by item id.
/// The open run counts here too: the cooking page sums the other runs
/// itself with `reservationsOf` over [cookRuns] without its own id.

final class CookRunReservationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, int>>,
          Map<String, int>,
          Stream<Map<String, int>>
        >
    with $FutureModifier<Map<String, int>>, $StreamProvider<Map<String, int>> {
  /// What all cook runs together take from each Vorrat item, by item id.
  /// The open run counts here too: the cooking page sums the other runs
  /// itself with `reservationsOf` over [cookRuns] without its own id.
  CookRunReservationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookRunReservationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookRunReservationsHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, int>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, int>> create(Ref ref) {
    return cookRunReservations(ref);
  }
}

String _$cookRunReservationsHash() =>
    r'3e3635c634354469ee8b1a22634bf2a22a6f9853';
