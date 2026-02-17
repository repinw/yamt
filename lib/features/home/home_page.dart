import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/l10n/app_localizations.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _debugSignOut(BuildContext context, WidgetRef ref) async {
    await ref.read(firebaseAuthProvider).signOut();
    if (!context.mounted) {
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            tooltip: 'Debug logout',
            icon: const Icon(Icons.logout),
            onPressed: () => _debugSignOut(context, ref),
          ),
        ],
      ),
      body: Center(
        child: Text(
          l10n.homeTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
