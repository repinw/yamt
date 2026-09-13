import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pops the product search hub route when local mutation state allows it.
void popProductSearchHubRoute({
  required BuildContext context,
  required bool isBlocked,
  Object? result,
}) {
  final router = GoRouter.maybeOf(context);
  final canPop =
      router != null ? router.canPop() : Navigator.of(context).canPop();
  if (isBlocked || !canPop) {
    return;
  }
  if (router != null) {
    router.pop<Object?>(result);
  } else {
    Navigator.of(context).pop<Object?>(result);
  }
}

/// Runs close preparation, then pops after current frame.
void popProductSearchHubDeferredRoute({
  required BuildContext context,
  required bool isBlocked,
  required VoidCallback prepareClose,
  Object? result,
}) {
  final router = GoRouter.maybeOf(context);
  final canPop =
      router != null ? router.canPop() : Navigator.of(context).canPop();
  if (isBlocked || !canPop) {
    return;
  }
  prepareClose();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) {
      return;
    }
    if (router != null && router.canPop()) {
      router.pop<Object?>(result);
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop<Object?>(result);
    }
  });
}

/// Shows product search hub feedback through the current scaffold.
void showProductSearchHubSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
