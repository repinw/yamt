import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

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
