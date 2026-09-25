import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_fonts.dart';
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
    this.secondaryLabel,
    this.secondaryButtonKey,
    this.onSecondary,
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

  /// Called by the confirm button.
  final VoidCallback onConfirm;

  /// Key of the close button.
  final Key cancelButtonKey;

  /// Text of an optional second button.
  final String? secondaryLabel;

  /// Key of the second button.
  final Key? secondaryButtonKey;

  /// Called by the second button.
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final secondary = secondaryLabel;
    final kcalValue = kcal;

    // An own messenger keeps snack bars of earlier entries off this page,
    // where they would cover the confirm button.
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: colors.paper,
        body: SafeArea(
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
                    whenControl,
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
              CustomPaint(
                painter: _DashedLinePainter(colors.ink),
                child: const SizedBox(
                  height: AppFoodLabel.outline,
                  width: double.infinity,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl + AppFoodLabel.buttonShadow,
                  AppSpacing.xl,
                ),
                child: Row(
                  spacing: AppSpacing.md,
                  children: [
                    if (secondary != null)
                      OutlinedButton(
                        key: secondaryButtonKey,
                        onPressed: onSecondary,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(
                            0,
                            AppSizes.primaryActionHeight,
                          ),
                          foregroundColor: colors.ink,
                          side: BorderSide(
                            color: colors.ink,
                            width: AppFoodLabel.outline,
                          ),
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: Text(
                          secondary,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontFamily: AppFonts.mono,
                                color: colors.ink,
                              ),
                        ),
                      ),
                    Expanded(
                      child: _ConfirmButton(
                        buttonKey: confirmButtonKey,
                        label: l10n.inventoryItemEatSheetConfirmAction,
                        trailing: kcalValue == null
                            ? null
                            : l10n.eatPageKcal(kcalValue.round()),
                        onPressed: onConfirm,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final trailingText = trailing;

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: colors.ink,
            offset: const Offset(
              AppFoodLabel.buttonShadow,
              AppFoodLabel.buttonShadow,
            ),
          ),
        ],
      ),
      child: FilledButton(
        key: buttonKey,
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.primaryActionHeight),
          backgroundColor: colors.accent,
          foregroundColor: colors.onAccent,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: colors.ink, width: AppFoodLabel.outline),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: textTheme.titleLarge?.copyWith(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w800,
                color: colors.onAccent,
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: AppFonts.mono,
                  fontWeight: FontWeight.w700,
                  color: colors.onAccent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const new(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += AppFoodLabel.dash * 2) {
      canvas.drawLine(Offset(x, y), Offset(x + AppFoodLabel.dash, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
