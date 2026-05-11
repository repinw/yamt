import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
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
        gradient: AppInventoryEditorialSurfaces.soulGradient(colors),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          AppInventoryEditorialSurfaces.ambientBoxShadow(
            colors,
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: SizedBox.square(
        dimension: AppInventoryEditorial.contextFabSize,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            enableFeedback: false,
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
