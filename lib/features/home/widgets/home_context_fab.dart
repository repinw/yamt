import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Floating action button for shell-level home actions.
class HomeContextFab extends StatelessWidget {
  /// The home context fab.
  const HomeContextFab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: SizedBox.square(
        dimension: 64,
        child: Material(
          color: Colors.transparent,
          child: AppInkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: () => _showSnackBar(
              context,
              l10n.homeSettingsActionContextPlaceholder,
            ),
            child: Tooltip(
              message: l10n.homeQuickActionTooltip,
              child: const Center(
                child: Icon(Icons.add, color: Colors.white, size: 36),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
