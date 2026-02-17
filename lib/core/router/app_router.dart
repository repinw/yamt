import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/auth/auth_page.dart';
import 'package:yamt/features/auth/welcome_page.dart';
import 'package:yamt/features/home/home_page.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.welcome,
    routes: [
      GoRoute(
        path: AppRoutes.root,
        redirect: (context, state) => AppRoutes.welcome,
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
