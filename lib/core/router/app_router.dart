import 'package:flutter/material.dart';
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
  final isAuthLoading = authState.isLoading;
  final user = authState.asData?.value;
  final isAuthenticated = user != null;

  return GoRouter(
    initialLocation: AppRoutes.root,
    redirect: (context, state) {
      final path = state.matchedLocation;
      final isSplashRoute = path == AppRoutes.splash;
      final isAuthRoute = path == AppRoutes.welcome || path == AppRoutes.auth;

      if (isAuthLoading) {
        return isSplashRoute ? null : AppRoutes.splash;
      }
      if (isSplashRoute) {
        return isAuthenticated ? AppRoutes.home : AppRoutes.welcome;
      }
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
        path: AppRoutes.splash,
        builder: (context, state) => const _AuthLoadingPage(),
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

class _AuthLoadingPage extends StatelessWidget {
  const _AuthLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
