import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';

/// Pops the product search hub route when local mutation state allows it.
void popProductSearchHubRoute({
  required BuildContext context,
  required bool isBlocked,
  Object? result,
}) {
  final router = GoRouter.maybeOf(context);
  final canPop = router != null
      ? router.canPop()
      : Navigator.of(context).canPop();
  if (isBlocked || !canPop) {
    return;
  }
  if (router != null) {
    router.pop<Object?>(result);
  } else {
    Navigator.of(context).pop<Object?>(result);
  }
}

/// Shows product search hub feedback through the current scaffold.
void showProductSearchHubSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
      .showAppSnackBar(message, tone: AppSnackBarTone.error);
}
