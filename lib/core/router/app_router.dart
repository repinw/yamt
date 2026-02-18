import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/auth/auth_page.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/auth/welcome_page.dart';
import 'package:yamt/features/home/home_page.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.asData?.value;
  final isAuthenticated = user != null;

  return GoRouter(
    initialLocation: AppRoutes.root,
    redirect: (context, state) {
      final path = state.matchedLocation;
      final isAuthRoute = path == AppRoutes.welcome || path == AppRoutes.auth;

      if (!isAuthenticated && path == AppRoutes.home) {
        return AppRoutes.welcome;
      }
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.root,
        redirect: (context, state) =>
            isAuthenticated ? AppRoutes.home : AppRoutes.welcome,
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'];
          final initialMode = mode == 'register'
              ? AuthMode.register
              : AuthMode.login;
          return AuthPage(initialMode: initialMode);
        },
      ),
    ],
  );
}
