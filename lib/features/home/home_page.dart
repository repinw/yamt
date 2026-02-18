import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/l10n/app_localizations.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _debugSignOut(WidgetRef ref) async {
    await ref.read(firebaseAuthProvider).signOut();
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
            onPressed: () => _debugSignOut(ref),
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
