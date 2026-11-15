import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_editor_draft.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Bottom of the recipe editor: the scan and paste tools and the lime
/// "Rezept speichern" button, with what the recipe still needs above it
/// ("Noch nötig: Name und eine Zutat") while it cannot be saved.
class RecipeEditorActions extends StatelessWidget {
  /// Creates the actions.
  const new({
    required this.draft,
    required this.isSaving,
    required this.onScan,
    required this.onPaste,
    required this.onSave,
    super.key,
  });

  /// Key of the scan tool.
  static const scanKey = ValueKey<String>('recipe-editor-scan');

  /// Key of the paste tool.
  static const pasteKey = ValueKey<String>('recipe-editor-paste');

  /// Key of the save button.
  static const saveKey = ValueKey<String>('recipe-editor-save');

  /// Key of "Noch nötig: …".
  static const missingKey = ValueKey<String>('recipe-editor-missing');

  /// The recipe as it would be saved, with the typed lines not added yet.
  final RecipeEditorDraft draft;

  /// Whether the recipe is being saved.
  final bool isSaving;

  /// Scans pages of a recipe; `null` disables the tool.
  final VoidCallback? onScan;

  /// Adds the lines on the clipboard; `null` disables the tool.
  final VoidCallback? onPaste;

  /// Saves the recipe; `null` disables the button.
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final missingName = draft.name.trim().isEmpty;
    final missingIngredient = draft.ingredients.isEmpty;

    final row = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          HomeHeaderTool(
            key: scanKey,
            symbol: Icon(Icons.document_scanner_outlined, color: colors.ink),
            label: l10n.recipeFromListScan,
            color: colors.ink,
            onPressed: onScan,
          ),
          HomeHeaderTool(
            key: pasteKey,
            symbol: Icon(Icons.content_paste_rounded, color: colors.ink),
            label: l10n.recipeEditorPaste,
            color: colors.ink,
            onPressed: onPaste,
          ),
          Expanded(
            child: FilledButton(
              key: saveKey,
              onPressed: onSave,
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.onAccent,
                minimumSize: const Size.fromHeight(AppGraphit.buttonHeight),
              ),
              child: isSaving
                  ? SizedBox.square(
                      dimension: AppGraphit.toolIcon,
                      child: CircularProgressIndicator(
                        strokeWidth: AppGraphit.highlightUnderline,
                        color: colors.ink,
                      ),
                    )
                  : Text(l10n.recipeFromListSave),
            ),
          ),
        ],
      ),
    );
    if (!missingName && !missingIngredient) return row;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            0,
          ),
          child: Text(
            l10n.recipeEditorMissing(switch ((missingName, missingIngredient)) {
              (true, true) => 'both',
              (true, false) => 'name',
              _ => 'ingredient',
            }),
            key: missingKey,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.muted),
          ),
        ),
        row,
      ],
    );
  }
}
