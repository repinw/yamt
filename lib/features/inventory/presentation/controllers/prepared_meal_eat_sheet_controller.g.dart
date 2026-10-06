// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal_eat_sheet_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the input of the eat sheet for one prepared meal.
///
/// With [followVorrat] the sheet works with [meal] as the Vorrat holds it
/// now, for example after its open rows were filled, and keeps what the user
/// entered when it changes.

@ProviderFor(PreparedMealEatSheetController)
final preparedMealEatSheetControllerProvider =
    PreparedMealEatSheetControllerFamily._();

/// Holds the input of the eat sheet for one prepared meal.
///
/// With [followVorrat] the sheet works with [meal] as the Vorrat holds it
/// now, for example after its open rows were filled, and keeps what the user
/// entered when it changes.
final class PreparedMealEatSheetControllerProvider
    extends
        $NotifierProvider<
          PreparedMealEatSheetController,
          PreparedMealEatSheetState
        > {
  /// Holds the input of the eat sheet for one prepared meal.
  ///
  /// With [followVorrat] the sheet works with [meal] as the Vorrat holds it
  /// now, for example after its open rows were filled, and keeps what the user
  /// entered when it changes.
  PreparedMealEatSheetControllerProvider._({
    required PreparedMealEatSheetControllerFamily super.from,
    required ({
      PreparedMeal meal,
      String localeName,
      DateTime? initialLoggedAt,
      MealType? initialMealType,
      bool followVorrat,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'preparedMealEatSheetControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$preparedMealEatSheetControllerHash();

  @override
  String toString() {
    return r'preparedMealEatSheetControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  PreparedMealEatSheetController create() => PreparedMealEatSheetController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreparedMealEatSheetState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreparedMealEatSheetState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PreparedMealEatSheetControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$preparedMealEatSheetControllerHash() =>
    r'd0e5634ee49d685f8c9c03fdef7fb86c1171d125';

/// Holds the input of the eat sheet for one prepared meal.
///
/// With [followVorrat] the sheet works with [meal] as the Vorrat holds it
/// now, for example after its open rows were filled, and keeps what the user
/// entered when it changes.

final class PreparedMealEatSheetControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          PreparedMealEatSheetController,
          PreparedMealEatSheetState,
          PreparedMealEatSheetState,
          PreparedMealEatSheetState,
          ({
            PreparedMeal meal,
            String localeName,
            DateTime? initialLoggedAt,
            MealType? initialMealType,
            bool followVorrat,
          })
        > {
  PreparedMealEatSheetControllerFamily._()
    : super(
        retry: null,
        name: r'preparedMealEatSheetControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Holds the input of the eat sheet for one prepared meal.
  ///
  /// With [followVorrat] the sheet works with [meal] as the Vorrat holds it
  /// now, for example after its open rows were filled, and keeps what the user
  /// entered when it changes.

  PreparedMealEatSheetControllerProvider call({
    required PreparedMeal meal,
    required String localeName,
    DateTime? initialLoggedAt,
    MealType? initialMealType,
    bool followVorrat = false,
  }) => PreparedMealEatSheetControllerProvider._(
    argument: (
      meal: meal,
      localeName: localeName,
      initialLoggedAt: initialLoggedAt,
      initialMealType: initialMealType,
      followVorrat: followVorrat,
    ),
    from: this,
  );

  @override
  String toString() => r'preparedMealEatSheetControllerProvider';
}

/// Holds the input of the eat sheet for one prepared meal.
///
/// With [followVorrat] the sheet works with [meal] as the Vorrat holds it
/// now, for example after its open rows were filled, and keeps what the user
/// entered when it changes.

abstract class _$PreparedMealEatSheetController
    extends $Notifier<PreparedMealEatSheetState> {
  late final _$args =
      ref.$arg
          as ({
            PreparedMeal meal,
            String localeName,
            DateTime? initialLoggedAt,
            MealType? initialMealType,
            bool followVorrat,
          });
  PreparedMeal get meal => _$args.meal;
  String get localeName => _$args.localeName;
  DateTime? get initialLoggedAt => _$args.initialLoggedAt;
  MealType? get initialMealType => _$args.initialMealType;
  bool get followVorrat => _$args.followVorrat;

  PreparedMealEatSheetState build({
    required PreparedMeal meal,
    required String localeName,
    DateTime? initialLoggedAt,
    MealType? initialMealType,
    bool followVorrat = false,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<PreparedMealEatSheetState, PreparedMealEatSheetState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PreparedMealEatSheetState, PreparedMealEatSheetState>,
              PreparedMealEatSheetState,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(
        meal: _$args.meal,
        localeName: _$args.localeName,
        initialLoggedAt: _$args.initialLoggedAt,
        initialMealType: _$args.initialMealType,
        followVorrat: _$args.followVorrat,
      ),
    );
  }
}
