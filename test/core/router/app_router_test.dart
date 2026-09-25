import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/app.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/core/widgets/home_bottom_nav_bar.dart';
import 'package:yamt/features/auth/application/'
    'auth_profile_setup_status_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/auth/domain/auth_profile_setup_preferences.dart';
import 'package:yamt/features/auth/domain/user_data_key_state.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_create_context.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/features/household/domain/household_invite.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/onboarding/domain/'
    'calorie_goal_onboarding_preferences.dart';
import 'package:yamt/features/onboarding/presentation/calorie_goal_onboarding_keys.dart';
import 'package:yamt/features/onboarding/provider/'
    'calorie_goal_onboarding_completed_provider.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_page.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_ai_search_page/product_ai_search_page.dart';

import '../../features/calories/support/fake_calories_repositories.dart';
import '../../helpers/memory_app_preferences.dart';

class _MockUser extends Mock implements User;

class _MockUserCredential extends Mock implements UserCredential;

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

const _routerTransitionDuration = Duration(milliseconds: 350);

class _MockUserMetadata extends Mock implements UserMetadata;

Future<void> _pumpRouterTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(_routerTransitionDuration);
}

/// Finds [icon] in the home navigation bar.
///
/// Page content can use the same icons, so the finder stays scoped to the bar.
Finder _homeNavIcon(IconData icon) {
  return find
      .descendant(
        of: find.byType(HomeBottomNavBar),
        matching: find.byIcon(icon),
      )
      .hitTestable();
}

/// Finds [icon] in the app bar of the current page.
///
/// Page content can use the same icons, so the finder stays scoped to the bar.
Finder _appBarIcon(IconData icon) {
  return find
      .descendant(of: find.byType(AppBar), matching: find.byIcon(icon))
      .hitTestable();
}

Future<void> _tapCalorieOnboardingNext(WidgetTester tester) async {
  final next = find.byKey(CalorieGoalOnboardingKeys.introNextAction);
  await tester.ensureVisible(next);
  await tester.tap(next);
  await tester.pumpAndSettle();
}

Future<void> _completeCalorieOnboarding(WidgetTester tester) async {
  _disableAnimations(tester);
  await tester.tap(find.byKey(CalorieGoalOnboardingKeys.introStartAction));
  await tester.pumpAndSettle();
  for (var storyPage = 0; storyPage < 6; storyPage++) {
    await _tapCalorieOnboardingNext(tester);
  }

  await tester.tap(find.text('Female'));
  await tester.pumpAndSettle();
  await _spinCalorieOnboardingWheel(
    tester,
    CalorieGoalOnboardingKeys.introBirthDayWheel,
  );
  await _tapCalorieOnboardingNext(tester);

  await _spinCalorieOnboardingWheel(
    tester,
    CalorieGoalOnboardingKeys.introHeightWheel,
  );
  await _spinCalorieOnboardingWheel(
    tester,
    CalorieGoalOnboardingKeys.introWeightWheel,
  );
  await _tapCalorieOnboardingNext(tester);

  await _spinCalorieOnboardingWheel(
    tester,
    CalorieGoalOnboardingKeys.introTargetWeightWheel,
  );
  await _tapCalorieOnboardingNext(tester);
  await _tapCalorieOnboardingNext(tester);

  await tester.tap(find.text('Lightly active'));
  await tester.pumpAndSettle();
  await _tapCalorieOnboardingNext(tester);

  await _tapCalorieOnboardingNext(tester);

  final finish = find.byKey(CalorieGoalOnboardingKeys.introFinishAction);
  await tester.ensureVisible(finish);
  await tester.tap(finish);
}

Future<void> _spinCalorieOnboardingWheel(
  WidgetTester tester,
  Key wheelKey,
) async {
  final wheel = find.byKey(wheelKey);
  await tester.ensureVisible(wheel);
  await tester.drag(wheel, const Offset(0, -60));
  await tester.pumpAndSettle();
}

UserMetadata _userMetadata({required bool isFirstSignIn}) {
  final metadata = _MockUserMetadata();
  final createdAt = DateTime.utc(2026, 1, 1, 9);
  final lastSignInAt = isFirstSignIn
      ? createdAt
      : createdAt.add(const Duration(days: 7));
  when(() => metadata.creationTime).thenReturn(createdAt);
  when(() => metadata.lastSignInTime).thenReturn(lastSignInAt);
  return metadata;
}

ProviderContainer _createContainerWithAuth(
  Stream<User?> authStream, {
  Set<String> completedProfileSetupUserIds = const <String>{},
  Set<String> completedCalorieGoalOnboardingUserIds = const <String>{},
  CalorieGoalSettings initialCalorieSettings =
      const CalorieGoalSettings.empty(),
  Future<UserCredential> Function()? onSignInAnonymously,
  UserDataKeyState? dataKeyState,
}) {
  final calorieLogRepository = FakeCalorieLogRepository();
  final calorieSettingsRepository = FakeCalorieSettingsRepository(
    initialSettings: initialCalorieSettings,
  );
  final broadcastAuthStream = authStream.isBroadcast
      ? authStream
      : authStream.asBroadcastStream();
  final appPreferences = MemoryAppPreferences(
    completedProfileSetupUserIds: completedProfileSetupUserIds,
    completedCalorieGoalOnboardingUserIds:
        completedCalorieGoalOnboardingUserIds,
  );
  final firebaseAuth = _MockFirebaseAuth();
  when(() => firebaseAuth.currentUser).thenReturn(null);
  if (onSignInAnonymously != null) {
    when(firebaseAuth.signInAnonymously)
        .thenAnswer((_) => onSignInAnonymously());
  }
  final container = ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWithValue(appPreferences),
      authStateChangesProvider.overrideWith((ref) => broadcastAuthStream),
      firebaseAuthProvider.overrideWithValue(firebaseAuth),
      calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(
        calorieSettingsRepository,
      ),
      inventoryItemRepositoryProvider.overrideWithValue(
        const _FakeInventoryItemRepository(),
      ),
      preparedMealRepositoryProvider.overrideWithValue(
        const _FakePreparedMealRepository(),
      ),
      burnWeekLiveSyncProvider.overrideWith((ref) => null),
      if (dataKeyState != null)
        userDataKeySessionProvider.overrideWith(
          () => _FakeUserDataKeySession(dataKeyState),
        ),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(calorieLogRepository.dispose);
  addTearDown(calorieSettingsRepository.dispose);
  return container;
}

_MockUser _authenticatedUser({
  String uid = 'uid-123',
  String? displayName = 'Jane Doe',
  String? email = 'jane@example.com',
  bool isFirstSignIn = false,
}) {
  final user = _MockUser();
  final metadata = _userMetadata(isFirstSignIn: isFirstSignIn);
  when(() => user.uid).thenReturn(uid);
  when(() => user.isAnonymous).thenReturn(false);
  when(() => user.displayName).thenReturn(displayName);
  when(() => user.email).thenReturn(email);
  when(() => user.metadata).thenReturn(metadata);
  return user;
}

_MockUser _guestUser({
  String uid = 'guest-123',
  String? displayName,
  bool isFirstSignIn = true,
}) {
  final user = _MockUser();
  final metadata = _userMetadata(isFirstSignIn: isFirstSignIn);
  when(() => user.uid).thenReturn(uid);
  when(() => user.isAnonymous).thenReturn(true);
  when(() => user.displayName).thenReturn(displayName);
  when(() => user.email).thenReturn(null);
  when(() => user.metadata).thenReturn(metadata);
  return user;
}

const _inventoryBackedCreateArgs = CalorieEntryCreateArgs(
  prefilledProfile: null,
  inventoryContext: CalorieInventoryCreateContext(
    inventoryItemId: 'inventory-1',
    foodFingerprint: 'milk',
    globalFoodItemId: 'off-milk',
    pendingConsumptionId: 'pending-1',
    inventoryAmountToRestore: 2,
    itemName: 'Milk',
    itemBrand: null,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
  ),
);

void _disableAnimations(WidgetTester tester) {
  tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
  );
}

void main() {
  testWidgets('shows splash while auth state is loading', (tester) async {
    final container = _createContainerWithAuth(
      Stream<User?>.fromFuture(
        Future<User?>.delayed(const Duration(milliseconds: 50), () => null),
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await tester.pump();

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.splash);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 60));
    await _pumpRouterTransition(tester);

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.welcome);
    expect(find.text('Yet Another Meal Tracker'), findsOneWidget);
  });

  testWidgets('keeps redirecting to splash while auth stream has not emitted', (
    tester,
  ) async {
    final authController = StreamController<User?>();
    final container = _createContainerWithAuth(authController.stream);
    addTearDown(() {
      unawaited(authController.close());
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await tester.pump();

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.splash);

    container.read(appRouterProvider).go(AppRoutes.home);
    await tester.pump();

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.splash);

    authController.add(null);
    await tester.pump();
    await _pumpRouterTransition(tester);

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.welcome);
    container.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('redirects root path to welcome', (tester) async {
    final container = _createContainerWithAuth(Stream<User?>.value(null));

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    container.read(appRouterProvider).go(AppRoutes.root);
    await _pumpRouterTransition(tester);

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.welcome);
    expect(find.text('Yet Another Meal Tracker'), findsOneWidget);
  });

  testWidgets('redirects unauthenticated user away from home', (tester) async {
    final container = _createContainerWithAuth(Stream<User?>.value(null));

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    container.read(appRouterProvider).go(AppRoutes.home);
    await _pumpRouterTransition(tester);

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.welcome);
  });

  testWidgets('redirects authenticated user away from welcome', (tester) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
      completedCalorieGoalOnboardingUserIds: {'uid-123'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);
    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.homeCalories,
    );

    container.read(appRouterProvider).go(AppRoutes.welcome);
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.homeCalories,
    );
  });

  testWidgets(
    'redirects anonymous user without calorie onboarding to calorie setup',
    (tester) async {
      final container = _createContainerWithAuth(
        Stream<User?>.value(_guestUser()),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const YAMT()),
      );
      await _pumpRouterTransition(tester);
      await _pumpRouterTransition(tester);

      expect(
        container.read(appRouterProvider).state.uri.path,
        AppRoutes.calorieGoalSetup,
      );
      expect(find.text('Welcome to YAMT'), findsOneWidget);
    },
  );

  testWidgets(
    'named anonymous user without calorie onboarding goes to calorie setup',
    (tester) async {
      final container = _createContainerWithAuth(
        Stream<User?>.value(_guestUser(displayName: 'Guest Name')),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const YAMT()),
      );
      await _pumpRouterTransition(tester);

      expect(
        container.read(appRouterProvider).state.uri.path,
        AppRoutes.calorieGoalSetup,
      );
    },
  );

  testWidgets('named anonymous user with setup marker is routed to home', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_guestUser(displayName: 'Guest Name')),
      completedProfileSetupUserIds: {'guest-123'},
      completedCalorieGoalOnboardingUserIds: {'guest-123'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.homeCalories,
    );
  });

  testWidgets('skips name setup for freshly created named user', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(
        _authenticatedUser(
          uid: 'fresh-user',
          displayName: 'Fresh Google User',
          isFirstSignIn: true,
        ),
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.calorieGoalSetup,
    );
  });

  testWidgets('skips setup for fresh user after setup completion marker', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(
        _authenticatedUser(
          uid: 'fresh-user',
          displayName: 'Fresh Google User',
          isFirstSignIn: true,
        ),
      ),
      completedProfileSetupUserIds: {'fresh-user'},
      completedCalorieGoalOnboardingUserIds: {'fresh-user'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.homeCalories,
    );
  });

  testWidgets(
    'redirects authenticated user without calorie onboarding to calorie setup',
    (tester) async {
      final container = _createContainerWithAuth(
        Stream<User?>.value(_authenticatedUser()),
        completedProfileSetupUserIds: {'uid-123'},
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const YAMT()),
      );
      await _pumpRouterTransition(tester);
      await _pumpRouterTransition(tester);

      expect(
        container.read(appRouterProvider).state.uri.path,
        AppRoutes.calorieGoalSetup,
      );
      expect(find.text('Welcome to YAMT'), findsOneWidget);
    },
  );

  testWidgets('saving calorie onboarding redirects to home', (tester) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.calorieGoalSetup,
    );

    await _completeCalorieOnboarding(tester);
    await tester.pump();
    await _pumpRouterTransition(tester);
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.homeCalories,
    );
  });

  testWidgets('existing calorie goal marks onboarding as completed', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
      initialCalorieSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 2, 25, 10),
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.homeCalories,
    );
    expect(
      container
          .read(appPreferencesProvider)
          .getStringSync(calorieGoalOnboardingKeyForUser('uid-123')),
      calorieGoalOnboardingCompletedValue,
    );
  });

  testWidgets(
    'skips name setup for returning named user without setup marker',
    (tester) async {
      final container = _createContainerWithAuth(
        Stream<User?>.value(
          _authenticatedUser(
            uid: 'returning-user',
            displayName: 'Returning Google User',
          ),
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const YAMT()),
      );
      await _pumpRouterTransition(tester);

      expect(
        container.read(appRouterProvider).state.uri.path,
        AppRoutes.calorieGoalSetup,
      );
    },
  );

  testWidgets(
    'stays on calorie setup after guest name update without onboarding',
    (tester) async {
      final authController = StreamController<User?>();
      final container = _createContainerWithAuth(authController.stream);
      addTearDown(() {
        unawaited(authController.close());
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const YAMT()),
      );
      await tester.pump();

      authController.add(_guestUser());
      await tester.pump();
      await _pumpRouterTransition(tester);

      expect(
        container.read(appRouterProvider).state.uri.path,
        AppRoutes.calorieGoalSetup,
      );

      authController.add(_guestUser(displayName: 'Guest Name'));
      await tester.pump();
      await _pumpRouterTransition(tester);

      expect(
        container.read(appRouterProvider).state.uri.path,
        AppRoutes.calorieGoalSetup,
      );
    },
  );

  testWidgets(
    'moves from guest setup to calorie setup and then home via markers',
    (tester) async {
      final authController = StreamController<User?>();
      final container = _createContainerWithAuth(authController.stream);
      addTearDown(() {
        unawaited(authController.close());
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const YAMT()),
      );
      await tester.pump();

      authController.add(
        _authenticatedUser(uid: 'setup-user', displayName: null),
      );
      await tester.pump();
      await _pumpRouterTransition(tester);

      expect(
        container.read(appRouterProvider).state.uri.path,
        AppRoutes.guestNameSetup,
      );

      await container
          .read(appPreferencesProvider)
          .setString(
            AuthProfileSetupPreferences.keyForUser('setup-user'),
            AuthProfileSetupPreferences.completedValue,
          );
      container.invalidate(authProfileSetupCompletedProvider);

      await tester.pump();
      await _pumpRouterTransition(tester);

      expect(
        container.read(appRouterProvider).state.uri.path,
        AppRoutes.calorieGoalSetup,
      );

      await container
          .read(appPreferencesProvider)
          .setString(
            calorieGoalOnboardingKeyForUser('setup-user'),
            calorieGoalOnboardingCompletedValue,
          );
      container.invalidate(calorieGoalOnboardingCompletedProvider);

      await tester.pump();
      await _pumpRouterTransition(tester);

      expect(
        container.read(appRouterProvider).state.uri.path,
        AppRoutes.homeCalories,
      );
    },
  );

  testWidgets('navigates between home destinations and updates route path', (
    tester,
  ) async {
    final user = _authenticatedUser();

    final container = _createContainerWithAuth(
      Stream<User?>.value(user),
      completedProfileSetupUserIds: {'uid-123'},
      completedCalorieGoalOnboardingUserIds: {'uid-123'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);
    await _pumpRouterTransition(tester);

    final router = container.read(appRouterProvider);
    expect(router.state.uri.path, AppRoutes.homeCalories);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('STATISTICS'), findsNothing);

    await tester.tap(_homeNavIcon(Icons.inventory_2_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(router.state.uri.path, AppRoutes.homeInventory);

    await tester.tap(find.byIcon(Icons.shopping_cart_rounded).hitTestable());
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeShopping);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Shopping')),
      findsOneWidget,
    );
    expect(_appBarIcon(Icons.arrow_back_rounded), findsOneWidget);

    await tester.tap(_appBarIcon(Icons.arrow_back_rounded));
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeInventory);

    router.go(AppRoutes.homeCalories);
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeCalories);
    expect(find.text('Today'), findsOneWidget);

    await tester.tap(_homeNavIcon(Icons.insights_rounded));
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeProgress);
    expect(find.byIcon(Icons.menu_rounded).hitTestable(), findsNothing);

    await tester.tap(_homeNavIcon(Icons.menu_book_rounded));
    await _pumpRouterTransition(tester);
    await tester.tap(find.byIcon(Icons.menu_rounded).hitTestable());
    await _pumpRouterTransition(tester);
    await tester.tap(find.text('Settings').hitTestable());
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeSettings);
    expect(find.byIcon(Icons.menu_rounded).hitTestable(), findsNothing);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Settings')),
      findsOneWidget,
    );

    router.go(AppRoutes.homeSettingsAccount);
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeSettingsAccount);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('a household invite link opens the household page', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
      completedCalorieGoalOnboardingUserIds: {'uid-123'},
    );
    final invite = HouseholdInvite(
      code: '123456',
      secret: RecoveryKey.generate(),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);
    final router = container.read(appRouterProvider);
    final link = Uri.parse(invite.link);
    router.go(Uri(path: link.path, query: link.query).toString());
    await _pumpRouterTransition(tester);

    expect(router.state.uri.path, AppRoutes.homeSettingsHousehold);
  });

  testWidgets('cookbook menu entry opens templates page', (tester) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
      completedCalorieGoalOnboardingUserIds: {'uid-123'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);
    await _pumpRouterTransition(tester);

    final router = container.read(appRouterProvider);
    expect(router.state.uri.path, AppRoutes.homeCalories);

    await tester.tap(find.byIcon(Icons.auto_stories_rounded).hitTestable());
    await _pumpRouterTransition(tester);

    expect(router.state.uri.path, AppRoutes.homeInventoryTemplates);
    expect(find.text('Cookbook'), findsWidgets);
    expect(find.byIcon(Icons.add_link_rounded), findsWidgets);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('route-level redirects for root and home routes are configured', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
      completedCalorieGoalOnboardingUserIds: {'uid-123'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    final router = container.read(appRouterProvider);
    final context = tester.element(find.byType(YAMT));
    final routes = router.configuration.routes.whereType<GoRoute>().toList();
    final rootRoute = routes.firstWhere(
      (route) => route.path == AppRoutes.root,
    );
    final homeRoute = routes.firstWhere(
      (route) => route.path == AppRoutes.home,
    );

    expect(
      rootRoute.redirect?.call(context, router.state),
      AppRoutes.homeCalories,
    );
    expect(
      homeRoute.redirect?.call(context, router.state),
      AppRoutes.homeCalories,
    );
  });

  testWidgets('appRouterProvider supports overrideWithValue', (tester) async {
    final stubRouter = GoRouter(
      routes: [
        GoRoute(
          path: AppRoutes.root,
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [appRouterProvider.overrideWithValue(stubRouter)],
    );
    addTearDown(container.dispose);

    expect(container.read(appRouterProvider), same(stubRouter));
  });

  testWidgets(
    'inventory-backed create opens a page and details route opens a sheet',
    (tester) async {
      final container = _createContainerWithAuth(
        Stream<User?>.value(_authenticatedUser()),
        completedProfileSetupUserIds: {'uid-123'},
        completedCalorieGoalOnboardingUserIds: {'uid-123'},
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const YAMT()),
      );
      await _pumpRouterTransition(tester);

      final router = container.read(appRouterProvider)
        ..go(
          AppRoutes.homeCaloriesEntryCreate,
          extra: _inventoryBackedCreateArgs,
        );
      await _pumpRouterTransition(tester);
      await _pumpRouterTransition(tester);
      expect(find.text('Add calorie entry'), findsOneWidget);
      expect(find.byKey(CalorieEntryEditorKeys.nameField), findsOneWidget);

      router.go(AppRoutes.homeCaloriesEntryCreate);
      await _pumpRouterTransition(tester);
      expect(router.state.uri.path, AppRoutes.homeInventory);

      router.go(AppRoutes.homeCaloriesEntryDetailsPath('missing-entry'));
      await _pumpRouterTransition(tester);
      await _pumpRouterTransition(tester);
      expect(find.text('Calorie entry details'), findsOneWidget);
      expect(find.text('Entry not found.'), findsOneWidget);
      expect(find.byType(ModalBarrier), findsOneWidget);
    },
  );

  testWidgets('product search hub route renders shell page', (tester) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
      completedCalorieGoalOnboardingUserIds: {'uid-123'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    final router = container.read(appRouterProvider);
    final routes = router.configuration.routes.whereType<GoRoute>().toList();
    final hubRoute = routes.firstWhere(
      (route) => route.path == AppRoutes.homeProductSearchHub,
    );

    expect(hubRoute.path, AppRoutes.homeProductSearchHub);

    router.go(AppRoutes.homeProductSearchHub);
    await _pumpRouterTransition(tester);

    expect(find.byType(ProductSearchHubPage), findsOneWidget);
    expect(find.text('Add to inventory'), findsOneWidget);
    expect(
      find.byKey(const Key('product_search_hub_recently_selected_empty_state')),
      findsOneWidget,
    );
  });

  testWidgets('product search hub search route renders focused page', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
      completedCalorieGoalOnboardingUserIds: {'uid-123'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    final router = container.read(appRouterProvider);
    final routes = router.configuration.routes.whereType<GoRoute>().toList();
    final searchRoute = routes.firstWhere(
      (route) => route.path == AppRoutes.homeProductSearchHubSearch,
    );

    expect(searchRoute.path, AppRoutes.homeProductSearchHubSearch);

    router.go(AppRoutes.homeProductSearchHubSearch);
    await _pumpRouterTransition(tester);

    expect(find.byType(ProductSearchHubSearchPage), findsOneWidget);
    expect(
      find.byKey(const Key('product_search_hub_search_field')),
      findsOneWidget,
    );
  });

  testWidgets('product search child flow route renders route args page', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
      completedCalorieGoalOnboardingUserIds: {'uid-123'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    final router = container.read(appRouterProvider);
    final routes = router.configuration.routes.whereType<GoRoute>().toList();
    final childRoute = routes.firstWhere(
      (route) => route.path == AppRoutes.productSearchChildFlow,
    );

    expect(childRoute.path, AppRoutes.productSearchChildFlow);

    final args = ManualProductSearchRouteArgs.aiSearch(
      item: InventoryItem.create(
        id: 'item-1',
        name: 'Placeholder',
        entryDate: DateTime.parse('2026-04-20T12:00:00Z'),
        storeName: 'Store',
        quantity: 1,
      ),
      initialPrompt: 'banana',
      showEatImmediatelyOption: false,
      initialAction: InventoryReceiptManualProductAction.addToInventory,
    );
    final payloadStore = container.read(
      manualProductSearchRoutePayloadStoreProvider,
    );
    final payloadId = payloadStore.put(args);
    addTearDown(() {
      payloadStore.remove(payloadId);
    });

    unawaited(router.push<void>(args.locationForPayload(payloadId)));
    await _pumpRouterTransition(tester);

    expect(find.byType(ManualProductAiSearchPage), findsOneWidget);
  });

  testWidgets(
    'restored product search child flow without args redirects to hub',
    (tester) async {
      final container = _createContainerWithAuth(
        Stream<User?>.value(_authenticatedUser()),
        completedProfileSetupUserIds: {'uid-123'},
        completedCalorieGoalOnboardingUserIds: {'uid-123'},
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const YAMT()),
      );
      await _pumpRouterTransition(tester);

      final router = container.read(appRouterProvider)
        ..go(
          AppRoutes.productSearchChildFlowPath(
            ManualProductSearchChildFlow.aiSearch.pathSegment,
          ),
        );
      await _pumpRouterTransition(tester);

      expect(tester.takeException(), isNull);
      expect(router.state.uri.path, AppRoutes.homeProductSearchHub);
      expect(find.byType(ProductSearchHubPage), findsOneWidget);
    },
  );

  testWidgets('cooking flow route is registered on app router', (tester) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
      completedCalorieGoalOnboardingUserIds: {'uid-123'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    final routes = container
        .read(appRouterProvider)
        .configuration
        .routes
        .whereType<GoRoute>()
        .toList();
    final cookingFlowRoute = routes.firstWhere(
      (route) => route.path == AppRoutes.homeInventoryTemplateDetail,
    );

    expect(cookingFlowRoute.path, AppRoutes.homeInventoryTemplateDetail);
  });

  testWidgets('kitchen utensils route is registered on app router', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
      completedCalorieGoalOnboardingUserIds: {'uid-123'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    final routes = container
        .read(appRouterProvider)
        .configuration
        .routes
        .whereType<GoRoute>()
        .toList();
    final kitchenUtensilsRoute = routes.firstWhere(
      (route) => route.path == AppRoutes.homeKitchenUtensils,
    );

    expect(kitchenUtensilsRoute.path, AppRoutes.homeKitchenUtensils);
  });

  testWidgets('allows navigating from onboarding to welcome and signs in', (
    tester,
  ) async {
    final authController = StreamController<User?>();
    final container = _createContainerWithAuth(
      authController.stream,
      completedProfileSetupUserIds: {'uid-existing'},
      completedCalorieGoalOnboardingUserIds: {'uid-existing'},
    );
    addTearDown(() {
      unawaited(authController.close());
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await tester.pump();

    authController.add(_guestUser());
    await tester.pump();
    await _pumpRouterTransition(tester);
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.calorieGoalSetup,
    );

    await tester.tap(find.byKey(CalorieGoalOnboardingKeys.introLoginAction));
    await _pumpRouterTransition(tester);

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.welcome);

    authController.add(_authenticatedUser(uid: 'uid-existing'));
    await tester.pump();
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.homeCalories,
    );
  });

  testWidgets('cold start with unauthenticated state triggers auto guest login '
      'and routes to onboarding', (tester) async {
    final guestSignInCompleter = Completer<UserCredential>();
    final authController = StreamController<User?>();
    final container = _createContainerWithAuth(
      authController.stream,
      onSignInAnonymously: () => guestSignInCompleter.future,
    );
    addTearDown(() {
      unawaited(authController.close());
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await tester.pump();

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.splash);

    authController.add(null);
    await tester.pump();

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.splash);

    final credential = _MockUserCredential();
    final guestUser = _guestUser();
    when(() => credential.user).thenReturn(guestUser);
    guestSignInCompleter.complete(credential);
    authController.add(guestUser);

    await tester.pump();
    await _pumpRouterTransition(tester);
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.calorieGoalSetup,
    );
    expect(find.text('Welcome to YAMT'), findsOneWidget);
  });

  testWidgets('asks for the recovery key on a new device', (tester) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
      completedCalorieGoalOnboardingUserIds: {'uid-123'},
      dataKeyState: const UserDataKeyRecoveryRequired(uid: 'uid-123'),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);
    await _pumpRouterTransition(tester);

    final router = container.read(appRouterProvider);
    expect(router.state.uri.path, AppRoutes.dataKey);
    expect(find.text('Restore your data'), findsOneWidget);

    router.go(AppRoutes.homeCalories);
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.dataKey);
  });

  testWidgets('an unsaved recovery key does not block the app', (tester) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
      completedCalorieGoalOnboardingUserIds: {'uid-123'},
      dataKeyState: UserDataKeyReady(
        uid: 'uid-123',
        cipher: PayloadCipher(SecretKey(List<int>.filled(32, 1))),
        recoveryKey: RecoveryKey.generate(),
        recoveryKeyConfirmed: false,
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.homeCalories,
    );
  });

  testWidgets('guest sign-in on welcome page routes to onboarding', (
    tester,
  ) async {
    final authController = StreamController<User?>();
    final container = _createContainerWithAuth(authController.stream);
    addTearDown(() {
      unawaited(authController.close());
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await tester.pump();

    authController.add(null);
    await tester.pump();
    await _pumpRouterTransition(tester);

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.welcome);

    authController.add(_guestUser());
    await tester.pump();
    await _pumpRouterTransition(tester);
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.calorieGoalSetup,
    );
    expect(find.text('Welcome to YAMT'), findsOneWidget);
  });
}

class _FakeUserDataKeySession extends UserDataKeySession {
  new(this._initialState);

  final UserDataKeyState _initialState;

  @override
  Future<UserDataKeyState> build() async => _initialState;
}

class _FakeInventoryItemRepository
    implements InventoryItemRepository, InventoryItemRecentManualReader {
  const new();

  @override
  bool get supportsLimitedRecentManualReads => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;

  @override
  Future<List<InventoryItem>> readAll() async {
    return const <InventoryItem>[];
  }

  @override
  Future<List<InventoryItem>> readRecentManualItems({
    required int limit,
  }) async {
    return const <InventoryItem>[];
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async => true;

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield const <InventoryItem>[];
  }
}

class _FakePreparedMealRepository implements PreparedMealRepository {
  const new();

  @override
  Future<List<PreparedMeal>> readAll() async {
    return const <PreparedMeal>[];
  }

  @override
  Future<bool> saveAll(List<PreparedMeal> meals) async => true;

  @override
  Stream<List<PreparedMeal>> watchAll() async* {
    yield const <PreparedMeal>[];
  }
}
