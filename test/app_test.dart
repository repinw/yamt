import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/app.dart';
import 'package:yamt/core/router/app_router.dart';

void main() {
  testWidgets('YAMT builds router app from provider', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('root')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appRouterProvider.overrideWithValue(router)],
        child: const YAMT(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('root'), findsOneWidget);
  });
}
