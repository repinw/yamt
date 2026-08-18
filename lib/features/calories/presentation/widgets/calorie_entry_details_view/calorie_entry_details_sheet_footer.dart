import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Fixed footer for calorie entry details actions.
class CalorieEntryDetailsSheetFooter extends StatelessWidget {
  /// Creates a details sheet footer.
  const CalorieEntryDetailsSheetFooter({
    required this.canReturn,
    required this.isSaving,
    required this.hasPendingChanges,
    required this.onSave,
    required this.onReturnToInventory,
    super.key,
  });

  /// Whether the entry can be returned to inventory.
  final bool canReturn;

  /// Whether a mutation is in progress.
  final bool isSaving;

  /// Whether meal/date edits are pending.
  final bool hasPendingChanges;

  /// Called when saving pending changes.
  final VoidCallback onSave;

  /// Called when returning the entry to inventory.
  final VoidCallback onReturnToInventory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppEditorial.glassBlur * 0.75,
          sigmaY: AppEditorial.glassBlur * 0.75,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest.withValues(alpha: 0.94),
            border: Border(
              top: BorderSide(
                color: AppEditorialSurfaces.ghostBorder(
                  colors,
                ).withValues(alpha: 0.9),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canReturn) ...[
                    TextButton.icon(
                      key: CalorieEntryDetailKeys.returnToInventoryButton,
                      onPressed: isSaving ? null : onReturnToInventory,
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: colors.onSurfaceVariant,
                      ),
                      label: Text(
                        l10n.caloriesRemoveEntryAction,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: CalorieEntryEditorKeys.saveButton,
                      onPressed: isSaving || !hasPendingChanges ? null : onSave,
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: Color.alphaBlend(
                          colors.primary.withValues(alpha: 0.14),
                          colors.surfaceContainerLowest,
                        ),
                        disabledBackgroundColor: colors.surfaceContainerLow,
                        foregroundColor: colors.primary,
                        disabledForegroundColor: colors.onSurfaceVariant
                            .withValues(alpha: 0.45),
                        side: BorderSide(
                          color: AppEditorialSurfaces.ghostBorder(
                            colors,
                          ).withValues(alpha: 0.9),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        elevation: 0,
                      ),
                      label: Text(
                        l10n.caloriesSaveEntryAction,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
