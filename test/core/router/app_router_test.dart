import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/app.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

class _MockUser extends Mock implements User {}

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
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go(AppRoutes.welcome);
    await tester.pumpAndSettle();

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.homeInventory,
    );
  });

  testWidgets('switches home tabs and updates route path', (tester) async {
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
    await tester.pumpAndSettle();

    final router = container.read(appRouterProvider);
    expect(router.state.uri.path, AppRoutes.homeInventory);

    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.homeShopping);

    await tester.tap(find.byIcon(Icons.local_fire_department_outlined));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.homeCalories);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.homeSettings);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
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
    await tester.pumpAndSettle();

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.homeInventory,
    );

    authController.add(null);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.welcome);
  });
}
