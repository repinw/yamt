// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cookbook_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Watches the saved Vorlagen and recipes of the household.

@ProviderFor(cookbookTemplates)
final cookbookTemplatesProvider = CookbookTemplatesProvider._();

/// Watches the saved Vorlagen and recipes of the household.

final class CookbookTemplatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PreparedMeal>>,
          List<PreparedMeal>,
          Stream<List<PreparedMeal>>
        >
    with
        $FutureModifier<List<PreparedMeal>>,
        $StreamProvider<List<PreparedMeal>> {
  /// Watches the saved Vorlagen and recipes of the household.
  CookbookTemplatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookbookTemplatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookbookTemplatesHash();

  @$internal
  @override
  $StreamProviderElement<List<PreparedMeal>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PreparedMeal>> create(Ref ref) {
    return cookbookTemplates(ref);
  }
}

String _$cookbookTemplatesHash() => r'9131567c0eb8f95744d4c5ff50bc7a814f636e24';

/// Holds the Kochbuch overview and rebuilds it when templates, meals, or the
/// Vorrat change.

@ProviderFor(CookbookController)
final cookbookControllerProvider = CookbookControllerFamily._();

/// Holds the Kochbuch overview and rebuilds it when templates, meals, or the
/// Vorrat change.
final class CookbookControllerProvider
    extends $AsyncNotifierProvider<CookbookController, CookbookOverview> {
  /// Holds the Kochbuch overview and rebuilds it when templates, meals, or the
  /// Vorrat change.
  CookbookControllerProvider._({
    required CookbookControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cookbookControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cookbookControllerHash();

  @override
  String toString() {
    return r'cookbookControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CookbookController create() => CookbookController();

  @override
  bool operator ==(Object other) {
    return other is CookbookControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cookbookControllerHash() =>
    r'017cc191f1202c9e008b5be774f1adc2d2236820';

/// Holds the Kochbuch overview and rebuilds it when templates, meals, or the
/// Vorrat change.

final class CookbookControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          CookbookController,
          AsyncValue<CookbookOverview>,
          CookbookOverview,
          FutureOr<CookbookOverview>,
          String
        > {
  CookbookControllerFamily._()
    : super(
        retry: null,
        name: r'cookbookControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Holds the Kochbuch overview and rebuilds it when templates, meals, or the
  /// Vorrat change.

  CookbookControllerProvider call(String localeCode) =>
      CookbookControllerProvider._(argument: localeCode, from: this);

  @override
  String toString() => r'cookbookControllerProvider';
}

/// Holds the Kochbuch overview and rebuilds it when templates, meals, or the
/// Vorrat change.

abstract class _$CookbookController extends $AsyncNotifier<CookbookOverview> {
  late final _$args = ref.$arg as String;
  String get localeCode => _$args;

  FutureOr<CookbookOverview> build(String localeCode);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<CookbookOverview>, CookbookOverview>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CookbookOverview>, CookbookOverview>,
              AsyncValue<CookbookOverview>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
