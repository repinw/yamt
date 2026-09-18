import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Kicker, headline, and lead text at the top of an intro page.
class IntroChapterHeader extends StatelessWidget {
  /// Creates a chapter header.
  const new({
    required this.kicker,
    required this.title,
    required this.accent,
    this.titleHighlight,
    this.body,
    this.alignment = CrossAxisAlignment.start,
    super.key,
  });

  /// Small label above the headline, for example `Chapter 2 · Expenditure`.
  final String kicker;

  /// Headline of the page.
  ///
  /// When it contains [titleHighlight], that part is drawn in [accent].
  final String title;

  /// Part of [title] that is drawn in the accent color.
  final String? titleHighlight;

  /// Lead text below the headline.
  final String? body;

  /// Accent color of this chapter.
  final Color accent;

  /// Horizontal alignment of the block.
  final CrossAxisAlignment alignment;

  bool get _isCentered => alignment == CrossAxisAlignment.center;

  /// Splits the title so the highlighted part can carry the accent color.
  InlineSpan _titleSpan(TextStyle? titleStyle, Color accent) {
    final highlight = titleHighlight;
    if (highlight == null || !title.contains(highlight)) {
      return TextSpan(text: title);
    }
    final start = title.indexOf(highlight);

    return TextSpan(
      children: [
        TextSpan(text: title.substring(0, start)),
        TextSpan(
          text: highlight,
          style: titleStyle?.copyWith(color: accent),
        ),
        TextSpan(text: title.substring(start + highlight.length)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textAlign = _isCentered ? TextAlign.center : TextAlign.start;
    final lead = body;
    final titleStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      height: AppIntroLayout.titleHeight,
      color: colors.onSurface,
    );

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSpacing.xs,
              height: AppSpacing.xs,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                kicker.toUpperCase(),
                textAlign: textAlign,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  letterSpacing: AppIntroLayout.kickerSpacing,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text.rich(
          _titleSpan(titleStyle, accent),
          textAlign: textAlign,
          style: titleStyle,
        ),
        if (lead != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            lead,
            textAlign: textAlign,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
