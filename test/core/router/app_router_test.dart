import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/app.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/auth/application/'
    'auth_profile_setup_status_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/domain/auth_profile_setup_preferences.dart';
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
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/onboarding/domain/'
    'calorie_goal_onboarding_preferences.dart';
import 'package:yamt/features/onboarding/presentation/calorie_goal_onboarding_keys.dart';
import 'package:yamt/features/onboarding/provider/'
    'calorie_goal_onboarding_completed_provider.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search/presentation/'
    'inventory_manual_add_page.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'product_ai_search_page/product_ai_search_page.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';

import '../../features/calories/support/fake_calories_repositories.dart';
import '../../helpers/memory_app_preferences.dart';

class _MockUser extends Mock implements User {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

const _routerTransitionDuration = Duration(milliseconds: 350);

class _MockUserMetadata extends Mock implements UserMetadata {}

Future<void> _pumpRouterTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(_routerTransitionDuration);
}

Future<void> _tapCalorieOnboardingNext(WidgetTester tester) async {
  final next = find.text('Next');
  final soundsGreat = find.text('Sounds great, next!');
  final button = next.evaluate().isNotEmpty ? next : soundsGreat;
  await tester.ensureVisible(button);
  await tester.tap(button);
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
  final container = ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWithValue(appPreferences),
      authStateChangesProvider.overrideWith((ref) => broadcastAuthStream),
      firebaseAuthProvider.overrideWithValue(firebaseAuth),
      calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(
        calorieSettingsRepository,
      ),
      burnWeekLiveSyncProvider.overrideWith((ref) => null),
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

@Dependencies([
  appRouter,
  inventoryItemRepository,
  inventoryBackedCalorieEntrySaveFlow,
  inventoryManualAddQuickEatConfig,
  manualProductRecentItemsService,
  InventoryItemsController,
  ReceiptBatchFlowController,
  ReceiptCaptureFlowController,
])
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

  testWidgets('redirects anonymous user without name to guest setup', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_guestUser()),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.guestNameSetup,
    );
    expect(find.text('Set your guest name'), findsOneWidget);
  });

  testWidgets('named anonymous user without setup marker stays in setup', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_guestUser(displayName: 'Guest Name')),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.guestNameSetup,
    );
  });

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

  testWidgets('redirects freshly created named user to setup page', (
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
      AppRoutes.guestNameSetup,
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
      expect(find.text('Glad you are here!'), findsOneWidget);
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

    await tester.tap(find.text("Let's start"));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Female'));
    await tester.enterText(find.byType(TextFormField).at(0), '30');
    await tester.enterText(find.byType(TextFormField).at(1), '170');
    await _tapCalorieOnboardingNext(tester);

    await _tapCalorieOnboardingNext(tester);

    await tester.enterText(find.byType(TextFormField).at(0), '70');
    await tester.enterText(find.byType(TextFormField).at(1), '70');
    await _tapCalorieOnboardingNext(tester);

    await _tapCalorieOnboardingNext(tester);
    await _tapCalorieOnboardingNext(tester);

    final startLaterOption = find.byKey(
      CalorieGoalOnboardingKeys.goalStartLaterOption,
    );
    await tester.ensureVisible(startLaterOption);
    await tester.tap(startLaterOption);
    await tester.pumpAndSettle();

    await _tapCalorieOnboardingNext(tester);

    await tester.ensureVisible(find.text("Let's go"));
    await tester.tap(find.text("Let's go"));
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

  testWidgets('redirects returning named user without setup marker to setup', (
    tester,
  ) async {
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
      AppRoutes.guestNameSetup,
    );
  });

  testWidgets('stays on guest setup after name update without setup marker', (
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

    authController.add(_guestUser());
    await tester.pump();
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.guestNameSetup,
    );

    authController.add(_guestUser(displayName: 'Guest Name'));
    await tester.pump();
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.guestNameSetup,
    );
  });

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

      authController.add(_authenticatedUser(uid: 'setup-user'));
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
    expect(find.text('MORE'), findsOneWidget);
    expect(find.text('STATISTICS'), findsNothing);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded).hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Statistics').hitTestable());
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeStatistics);
    expect(find.text('MVP note'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.inventory_2_rounded).hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(router.state.uri.path, AppRoutes.homeInventory);

    await tester.tap(find.byIcon(Icons.shopping_cart_rounded).hitTestable());
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeShopping);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded).hitTestable());
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeInventory);

    router.go(AppRoutes.homeCalories);
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeCalories);
    expect(find.text('Today'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded).hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Settings').hitTestable());
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeSettings);
    expect(find.text('Settings'), findsWidgets);

    router.go(AppRoutes.homeSettingsAccount);
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeSettingsAccount);
    expect(find.text('Sign out'), findsOneWidget);
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
    expect(find.text('Cookbook'), findsOneWidget);
    expect(find.byIcon(Icons.add_link_rounded), findsOneWidget);
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
    (
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

  testWidgets('statistics weight route is registered on app router', (
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
    final trendsRoute = routes.firstWhere(
      (route) => route.path == AppRoutes.homeStatisticsWeight,
    );

    expect(trendsRoute.path, AppRoutes.homeStatisticsWeight);
  });

  testWidgets('inventory manual add route is registered on app router', (
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
    final manualAddRoute = routes.firstWhere(
      (route) => route.path == AppRoutes.homeInventoryManualAdd,
    );

    expect(manualAddRoute.path, AppRoutes.homeInventoryManualAdd);
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

    unawaited(
      router.push<void>(args.locationForPayload(payloadId)),
    );
    await _pumpRouterTransition(tester);

    expect(find.byType(ManualProductAiSearchPage), findsOneWidget);
  });

  testWidgets(
    'restored product search child flow without args redirects to manual add',
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
      expect(router.state.uri.path, AppRoutes.homeInventoryManualAdd);
      expect(find.byType(InventoryManualAddPage), findsOneWidget);
    },
  );

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

  test(
    'inventory manual add route args support new, legacy, and bad extras',
    () {
      final loggedAt = DateTime(2026, 5, 9, 12, 30);
      final routeArgs = InventoryManualAddRouteArgs(
        initialAction: InventoryManualAddInitialAction.barcodeScan,
        quickEatOnly: true,
        preselectedMealType: MealType.dinner,
        preselectedLoggedAt: loggedAt,
      );

      expect(resolveInventoryManualAddRouteArgs(routeArgs), same(routeArgs));

      final legacyArgs = resolveInventoryManualAddRouteArgs(
        InventoryManualAddInitialAction.aiSuggestion,
      );
      expect(
        legacyArgs.initialAction,
        InventoryManualAddInitialAction.aiSuggestion,
      );
      expect(legacyArgs.quickEatOnly, isFalse);
      expect(legacyArgs.preselectedMealType, isNull);
      expect(legacyArgs.preselectedLoggedAt, isNull);

      for (final badExtra in <Object?>[null, 'unexpected']) {
        final fallbackArgs = resolveInventoryManualAddRouteArgs(badExtra);
        expect(
          fallbackArgs.initialAction,
          InventoryManualAddInitialAction.launcher,
        );
        expect(fallbackArgs.quickEatOnly, isFalse);
      }
    },
  );
}
