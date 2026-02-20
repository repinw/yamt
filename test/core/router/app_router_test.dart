import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/app.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

class _MockUser extends Mock implements User {}

Future<void> _pumpUntilPath(
  WidgetTester tester,
  ProviderContainer container,
  String expectedPath,
) async {
  for (var i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    final currentPath = container.read(appRouterProvider).state.uri.path;
    if (currentPath == expectedPath) {
      return;
    }
  }

  final lastPath = container.read(appRouterProvider).state.uri.path;
  fail('Expected route "$expectedPath", got "$lastPath".');
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  fail('Did not find expected widget: $finder');
}

void main() {
  testWidgets('shows splash while auth state is loading', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.fromFuture(
            Future<User?>.delayed(const Duration(milliseconds: 50), () => null),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await tester.pump();

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.splash);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.welcome);
    expect(find.text('Yet Another Meal Tracker'), findsOneWidget);
  });

  testWidgets('keeps redirecting to splash while auth stream has not emitted', (
    tester,
  ) async {
    final authController = StreamController<User?>();
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => authController.stream),
      ],
    );
    addTearDown(authController.close);
    addTearDown(container.dispose);

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
    await tester.pumpAndSettle();

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.welcome);
  });

  testWidgets('redirects root path to welcome', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(null),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go(AppRoutes.root);
    await tester.pumpAndSettle();

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.welcome);
    expect(find.text('Yet Another Meal Tracker'), findsOneWidget);
  });

  testWidgets('redirects unauthenticated user away from home', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(null),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go(AppRoutes.home);
    await tester.pumpAndSettle();

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.welcome);
  });

  testWidgets('redirects authenticated user away from welcome', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(_MockUser()),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpUntilPath(tester, container, AppRoutes.homeInventory);

    container.read(appRouterProvider).go(AppRoutes.welcome);
    await _pumpUntilPath(tester, container, AppRoutes.homeInventory);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.homeInventory,
    );
  });

  testWidgets('switches home tabs and updates route path', (tester) async {
    final user = _MockUser();
    when(() => user.isAnonymous).thenReturn(false);
    when(() => user.displayName).thenReturn('Jane Doe');
    when(() => user.email).thenReturn('jane@example.com');
    when(() => user.uid).thenReturn('uid-123');

    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(user),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpUntilPath(tester, container, AppRoutes.homeInventory);

    final router = container.read(appRouterProvider);
    expect(router.state.uri.path, AppRoutes.homeInventory);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Inventory'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await _pumpUntilPath(tester, container, AppRoutes.homeShopping);
    expect(router.state.uri.path, AppRoutes.homeShopping);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Shopping')),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.local_fire_department_outlined));
    await _pumpUntilPath(tester, container, AppRoutes.homeCalories);
    expect(router.state.uri.path, AppRoutes.homeCalories);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Calories')),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.settings));
    await _pumpUntilPath(tester, container, AppRoutes.homeSettings);
    expect(router.state.uri.path, AppRoutes.homeSettings);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Settings')),
      findsOneWidget,
    );
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);

    await tester.tap(find.text('Account').first);
    await _pumpUntilPath(tester, container, AppRoutes.homeSettingsAccount);
    expect(router.state.uri.path, AppRoutes.homeSettingsAccount);
    await _pumpUntilFound(tester, find.text('Sign out'));
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('redirects to welcome after logout from a home route', (
    tester,
  ) async {
    final authController = StreamController<User?>();
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => authController.stream),
      ],
    );
    addTearDown(authController.close);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await tester.pump();

    authController.add(_MockUser());
    await tester.pump();
    await _pumpUntilPath(tester, container, AppRoutes.homeInventory);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.homeInventory,
    );

    authController.add(null);
    await tester.pump();
    await _pumpUntilPath(tester, container, AppRoutes.welcome);

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.welcome);
  });

  testWidgets('route-level redirects for root and home routes are configured', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(_MockUser()),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpUntilPath(tester, container, AppRoutes.homeInventory);

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
      AppRoutes.homeInventory,
    );
    expect(
      homeRoute.redirect?.call(context, router.state),
      AppRoutes.homeInventory,
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
}
