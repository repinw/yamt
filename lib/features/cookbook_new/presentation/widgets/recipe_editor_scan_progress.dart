import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The top of the recipe editor while a scan or paste is being read.
class RecipeEditorScanProgress extends StatelessWidget {
  /// Creates the progress.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xs,
        children: [
          const LinearProgressIndicator(),
          Text(AppLocalizations.of(context)!.recipeFromListScanning),
        ],
      ),
    );
  }
}
