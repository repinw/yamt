import 'package:flutter/material.dart';
import 'package:yamt/l10n/app_localizations.dart';

enum HomeTabType { inventory, calories, settings }

class HomeTabPage extends StatelessWidget {
  const HomeTabPage({super.key, required this.tab});

  final HomeTabType tab;

  String _titleFor(AppLocalizations l10n) {
    switch (tab) {
      case HomeTabType.inventory:
        return l10n.homeInventory;
      case HomeTabType.calories:
        return l10n.homeCalories;
      case HomeTabType.settings:
        return l10n.homeSettings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Text(
        _titleFor(l10n),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}
