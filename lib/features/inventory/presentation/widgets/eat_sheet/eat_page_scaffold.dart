import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Full-screen frame of the eat page: a top bar with close and time, the
/// scrolling content, and the confirm button at the bottom.
class EatPageScaffold extends StatelessWidget {
  /// Creates the eat page frame.
  const new({
    required this.whenControl,
    required this.children,
    required this.kcal,
    required this.confirmButtonKey,
    required this.onConfirm,
    required this.cancelButtonKey,
    this.confirmLabel,
    this.secondaryLabel,
    this.secondaryButtonKey,
    this.onSecondary,
    this.hasOwnMessenger = true,
    this.confirmHint,
    super.key,
  });

  /// Control for the day and meal, shown top right.
  final Widget whenControl;

  /// Page content.
  final List<Widget> children;

  /// Calories of the entered amount, shown on the confirm button. Hidden
  /// when unknown.
  final double? kcal;

  /// Key of the confirm button.
  final Key confirmButtonKey;

  /// Called by the confirm button. The button is disabled when null.
  final VoidCallback? onConfirm;

  /// Text of the confirm button. Defaults to "Log".
  final String? confirmLabel;

  /// Key of the close button.
  final Key cancelButtonKey;

  /// Text of an optional second button.
  final String? secondaryLabel;

  /// Key of the second button.
  final Key? secondaryButtonKey;

  /// Called by the second button.
  final VoidCallback? onSecondary;

  /// Whether the page shows only its own snack bars. Without an own
  /// messenger, snack bars that the caller shows through the route's
  /// context appear on this page.
  final bool hasOwnMessenger;

  /// Small grey line above the buttons, such as what is still missing.
  final String? confirmHint;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final secondary = secondaryLabel;
    final kcalValue = kcal;

    final scaffold = Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    key: cancelButtonKey,
                    tooltip: MaterialLocalizations.of(context)
                        .closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: colors.ink),
                  ),
                  // A long day and meal shrinks instead of overflowing.
                  Flexible(child: whenControl),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.xs,
                  AppSpacing.xxl,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.xxl,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
      // Snack bars of this page float above the buttons instead of
      // covering them.
      bottomNavigationBar: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.rule)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: [
                if (confirmHint case final hint?)
                  Text(
                    hint,
                    key: const Key('eat_page_confirm_hint'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.muted),
                  ),
                Row(
                  spacing: AppSpacing.xs,
                  children: [
                    if (secondary != null)
                      FilledButton.tonal(
                        key: secondaryButtonKey,
                        onPressed: onSecondary,
                        child: Text(secondary),
                      ),
                    Expanded(
                      child: _ConfirmButton(
                        buttonKey: confirmButtonKey,
                        label:
                            confirmLabel ??
                            l10n.inventoryItemEatSheetConfirmAction,
                        trailing: kcalValue == null
                            ? null
                            : l10n.eatPageKcal(kcalValue.round()),
                        onPressed: onConfirm,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // An own messenger keeps snack bars of earlier entries off this page.
    return hasOwnMessenger ? ScaffoldMessenger(child: scaffold) : scaffold;
  }
}

/// The one lime action of the page: the label, and the calories of the
/// entered amount in a small tag.
class _ConfirmButton extends StatelessWidget {
  const new({
    required this.buttonKey,
    required this.label,
    required this.trailing,
    required this.onPressed,
  });

  final Key buttonKey;
  final String label;
  final String? trailing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final trailingText = trailing;

    return FilledButton(
      key: buttonKey,
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xs, 0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: AppSpacing.sm,
        children: [
          // A long label next to a second button shrinks instead of
          // overflowing.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(label, maxLines: 1),
            ),
          ),
          if (trailingText != null)
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.onAccent.withValues(
                  alpha: AppOpacities.buttonTag,
                ),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                child: Text(
                  trailingText,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onAccent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
