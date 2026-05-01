import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

/// Shared sticky footer for inventory eat flows.
class InventoryEatFlowFooter extends StatelessWidget {
  /// Creates shared footer.
  const InventoryEatFlowFooter({
    required this.confirmActionText,
    required this.confirmButtonKey,
    required this.onConfirm,
    super.key,
  });

  /// Confirm action text.
  final String confirmActionText;

  /// Confirm button key.
  final Key confirmButtonKey;

  /// Confirm callback.
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: AppInventoryEditorialSurfaces.ghostBorder(colors),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: confirmButtonKey,
            onPressed: onConfirm,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              backgroundColor: colors.primary,
            ),
            child: Text(
              confirmActionText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
