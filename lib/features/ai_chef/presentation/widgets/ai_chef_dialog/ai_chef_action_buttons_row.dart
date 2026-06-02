import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Displays result dialog action buttons.
class AiChefActionButtonsRow extends StatelessWidget {
  /// Creates action buttons row.
  const AiChefActionButtonsRow({
    required this.onClose,
    required this.onSave,
    required this.isSaving,
    super.key,
  });

  /// Triggered when user closes generated recipe.
  final VoidCallback onClose;

  /// Triggered when user saves generated recipe.
  final VoidCallback onSave;

  /// Whether the save action is running.
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isSaving ? null : onClose,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: Text(l10n.aiChefCloseAction),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: isSaving
                  ? null
                  : AppEditorialSurfaces.soulGradient(colors),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: FilledButton(
              onPressed: isSaving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: _SaveButtonContent(isSaving: isSaving, l10n: l10n),
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveButtonContent extends StatelessWidget {
  const _SaveButtonContent({required this.isSaving, required this.l10n});

  final bool isSaving;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (isSaving) {
      return const SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Text(
      l10n.aiChefSaveAction,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
}
