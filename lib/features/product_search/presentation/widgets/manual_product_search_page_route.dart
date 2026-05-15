import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';

/// Route arguments for a product-search child flow.
class ManualProductSearchRouteArgs {
  /// Creates product-search child route args.
  const ManualProductSearchRouteArgs({required this.builder});

  /// Builds the child page.
  final WidgetBuilder builder;
}

/// Pushes a nested manual product flow page without route animation.
Future<T?> pushManualProductSearchPage<T extends Object?>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return GoRouter.of(context).push<T>(
    AppRoutes.productSearchChildFlow,
    extra: ManualProductSearchRouteArgs(builder: builder),
  );
}

/// Pops a manual product flow page through go_router.
void popManualProductSearchPage<T extends Object?>(
  BuildContext context, [
  T? result,
]) {
  context.pop<T>(result);
}
