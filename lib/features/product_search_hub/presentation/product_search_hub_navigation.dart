import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pops the product search hub route when local mutation state allows it.
void popProductSearchHubRoute({
  required BuildContext context,
  required bool isBlocked,
  Object? result,
}) {
  final router = GoRouter.maybeOf(context);
  if (isBlocked || router == null || !router.canPop()) {
    return;
  }
  router.pop<Object?>(result);
}

/// Runs close preparation, then pops after current frame.
void popProductSearchHubDeferredRoute({
  required BuildContext context,
  required bool isBlocked,
  required VoidCallback prepareClose,
  Object? result,
}) {
  final router = GoRouter.maybeOf(context);
  if (isBlocked || router == null || !router.canPop()) {
    return;
  }
  prepareClose();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted && router.canPop()) {
      router.pop<Object?>(result);
    }
  });
}

/// Shows product search hub feedback through the current scaffold.
void showProductSearchHubSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
