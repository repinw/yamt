import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/utils/text_measure.dart';

/// One muted line of a tile: an optional icon and a short text that ends
/// with an ellipsis when the tile is narrow, or, with [wholeOnly] and large
/// text, drops out when the whole text does not fit.
class DiaryTileCaption extends StatelessWidget {
  /// Creates the caption [text].
  const new(
    this.text, {
    this.icon,
    this.color,
    this.wholeOnly = false,
    this.semanticsLabel,
    super.key,
  });

  /// The text.
  final String text;

  /// Icon before the text.
  final IconData? icon;

  /// Whether the text shows, at large text, only when it fits whole, instead
  /// of ending with an ellipsis in the middle of a word; the icon stays. A
  /// screen reader still reads the text.
  final bool wholeOnly;

  /// What a screen reader says instead of [text], for a short form of it.
  final String? semanticsLabel;

  /// Color of icon and text; muted by default.
  final Color? color;

  /// The text style of a caption, without its color.
  static TextStyle? styleOf(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall
          ?.copyWith(fontFamily: AppFonts.geist);

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? FoodLabelColors.of(context).muted;
    final style = styleOf(context)?.copyWith(color: color);

    Widget row(bool showText) => !showText && icon == null
        ? Semantics(label: text, child: const SizedBox.shrink())
        : Row(
            spacing: AppDashboard.captionGap,
            children: [
              if (icon case final icon?)
                Icon(
                  icon,
                  size: AppDashboard.captionIcon,
                  color: color,
                  // Where the text drops out, the icon says it.
                  semanticLabel: showText ? null : text,
                ),
              if (showText)
                Flexible(
                  child: Text(
                    text,
                    semanticsLabel: semanticsLabel,
                    style: style,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          );

    if (!wholeOnly || !isLargeText(context)) return row(true);
    final iconWidth = icon == null
        ? 0.0
        : AppDashboard.captionIcon + AppDashboard.captionGap;
    return LayoutBuilder(
      builder: (context, constraints) => row(
        textFitsWholeWords(
          context,
          text,
          style,
          maxWidth: constraints.maxWidth - iconWidth,
        ),
      ),
    );
  }
}
