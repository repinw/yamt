import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Page that presents its child in a modal bottom sheet.
class ModalBottomSheetPage<T> extends Page<T> {
  /// Creates a modal bottom sheet page.
  const new({required this.child, super.key});

  /// Child widget displayed in the bottom sheet.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute<T>(
      settings: this,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => child,
    );
  }
}

/// Loading indicator page rendered on startup while auth resolves.
class AuthLoadingPage extends StatelessWidget {
  /// Creates an auth loading page.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Extracts and validates required typed route extra argument.
T requireRouteExtra<T>(GoRouterState state, String message) {
  final args = state.extra;
  if (args is! T) {
    throw ArgumentError(message);
  }
  return args;
}
