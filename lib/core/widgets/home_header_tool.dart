import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

/// Action of a home tab header: a symbol with a small word under it.
///
/// Every header action shows its word, so the header says what it does. The
/// symbol is usually an [Icon]; the diary day type shows an emoji [Text].
class HomeHeaderTool extends StatelessWidget {
  /// Creates a header tool.
  const new({
    required this.symbol,
    required this.label,
    required this.onPressed,
    this.color,
    super.key,
  });

  /// Icon or emoji above the word.
  final Widget symbol;

  /// Word under the symbol, shown in capitals.
  final String label;

  /// Called on tap. The tool is disabled when this is `null`.
  final VoidCallback? onPressed;

  /// Color of the symbol and the word; the surface's text color when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final content = color ?? colors.onSurface;
    final foreground = onPressed == null
        ? content.withValues(alpha: AppOpacities.disabledContent)
        : content;

    // The word is the label; the tap action is set here because the ink
    // well's own semantics are excluded with the visual content.
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: AppInkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSizes.headerTool,
            minHeight: AppSizes.headerTool,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconTheme.merge(
                  data: IconThemeData(
                    color: foreground,
                    size: AppSizes.headerToolSymbol,
                  ),
                  child: DefaultTextStyle.merge(
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: AppSizes.headerToolSymbol,
                      height: 1,
                    ),
                    child: symbol,
                  ),
                ),
                const SizedBox(height: AppSizes.headerToolGap),
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: AppFontSizes.labelXSmall,
                    fontWeight: FontWeight.w600,
                    letterSpacing: AppFoodLabel.navLabelTracking,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
