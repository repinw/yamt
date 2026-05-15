import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_route.dart';

void main() {
  testWidgets('push helper returns typed result without route animation', (
    tester,
  ) async {
    String? result;

    final router = _buildManualProductRouteTestRouter(
      homeBuilder: (context) {
        return Scaffold(
          body: FilledButton(
            key: const Key('open_manual_product_route'),
            onPressed: () {
              unawaited(
                pushManualProductSearchPage<String>(
                  context: context,
                  builder: (_) {
                    return Builder(
                      builder: (routeContext) {
                        return Scaffold(
                          body: FilledButton(
                            key: const Key('close_manual_product_route'),
                            onPressed: () {
                              popManualProductSearchPage(routeContext, 'done');
                            },
                            child: const Text('close'),
                          ),
                        );
                      },
                    );
                  },
                ).then((value) => result = value),
              );
            },
            child: const Text('open'),
          ),
        );
      },
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.byKey(const Key('open_manual_product_route')));
    await tester.pump();

    expect(
      find.byKey(const Key('close_manual_product_route')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('close_manual_product_route')));
    await tester.pumpAndSettle();

    expect(result, 'done');
  });

  testWidgets('pop helper delegates to go_router when available', (
    tester,
  ) async {
    final router = _buildManualProductRouteTestRouter(
      homeBuilder: (context) {
        return Scaffold(
          body: FilledButton(
            key: const Key('open_go_router_route'),
            onPressed: () => unawaited(
              pushManualProductSearchPage<String>(
                context: context,
                builder: (routeContext) {
                  return Scaffold(
                    body: FilledButton(
                      key: const Key('close_go_router_route'),
                      onPressed: () {
                        popManualProductSearchPage(routeContext, 'done');
                      },
                      child: const Text('child'),
                    ),
                  );
                },
              ),
            ),
            child: const Text('home'),
          ),
        );
      },
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.byKey(const Key('open_go_router_route')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('close_go_router_route')), findsOneWidget);

    await tester.tap(find.byKey(const Key('close_go_router_route')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('open_go_router_route')), findsOneWidget);
  });
}

GoRouter _buildManualProductRouteTestRouter({
  required WidgetBuilder homeBuilder,
}) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => homeBuilder(context)),
      GoRoute(
        path: AppRoutes.productSearchChildFlow,
        pageBuilder: (context, state) {
          final args = state.extra! as ManualProductSearchRouteArgs;
          return NoTransitionPage<Object?>(
            key: state.pageKey,
            child: args.builder(context),
          );
        },
      ),
    ],
  );
}
