import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';

/// Shared sticky footer for inventory eat flows.
class InventoryEatFlowFooter extends StatelessWidget {
  /// Creates shared footer.
  const InventoryEatFlowFooter({
    required this.confirmActionText,
    required this.confirmButtonKey,
    required this.onConfirm,
    this.secondaryActionText,
    this.secondaryButtonKey,
    this.onSecondaryConfirm,
    super.key,
  });

  /// Confirm action text.
  final String confirmActionText;

  /// Confirm button key.
  final Key confirmButtonKey;

  /// Confirm callback.
  final VoidCallback onConfirm;

  /// Optional secondary action text.
  final String? secondaryActionText;

  /// Optional secondary button key.
  final Key? secondaryButtonKey;

  /// Optional secondary callback.
  final VoidCallback? onSecondaryConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: AppEditorialSurfaces.ghostBorder(colors),
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
        child: secondaryActionText == null
            ? _ConfirmButton(
                buttonKey: confirmButtonKey,
                text: confirmActionText,
                colors: colors,
                onPressed: onConfirm,
              )
            : Row(
                children: [
                  Expanded(
                    child: _SecondaryButton(
                      buttonKey: secondaryButtonKey,
                      text: secondaryActionText!,
                      onPressed: onSecondaryConfirm,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ConfirmButton(
                      buttonKey: confirmButtonKey,
                      text: confirmActionText,
                      colors: colors,
                      onPressed: onConfirm,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.buttonKey,
    required this.text,
    required this.onPressed,
  });

  final Key? buttonKey;
  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: buttonKey,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.buttonKey,
    required this.text,
    required this.colors,
    required this.onPressed,
  });

  final Key buttonKey;
  final String text;
  final ColorScheme colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: buttonKey,
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        backgroundColor: colors.primary,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colors.onPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
