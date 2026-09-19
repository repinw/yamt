import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

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
