import 'package:material_ui/material_ui.dart';

/// Whether the user set text larger than the default size.
///
/// The dashboard tiles and the budget card look as they always did at the
/// default size; only larger text makes them drop what does not fit whole.
bool isLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) > 1;

/// Width of [span] set on one line as `Text.rich` sets it, at the text scale
/// of [context] and in the default text style it would inherit there.
///
/// The Bold Text setting makes only the inherited style bold, so a span
/// with a font weight of its own keeps it. For `Text(text, style: style)`
/// use [measureTextWidth], where the setting wins over the style.
double measureLineWidth(BuildContext context, InlineSpan span) {
  final painter = _painter(context, span, maxLines: 1)..layout();
  try {
    return painter.width;
  } finally {
    painter.dispose();
  }
}

/// Width of [text] in [style] set on one line as `Text(text, style: style)`
/// sets it, with the Bold Text setting applied.
double measureTextWidth(BuildContext context, String text, TextStyle? style) =>
    measureLineWidth(context, _plainSpan(context, text, style));

/// Whether [text] set in [style] fits [maxWidth] by [maxHeight] in at most
/// [maxLines] lines without breaking inside a word.
///
/// A word wider than [maxWidth] fails, which `maxLines` and an ellipsis
/// alone cannot prevent: the text breaks it across lines.
bool textFitsWholeWords(
  BuildContext context,
  String text,
  TextStyle? style, {
  required double maxWidth,
  double maxHeight = double.infinity,
  int maxLines = 1,
}) {
  final whole = _painter(
    context,
    _plainSpan(context, text, style),
    maxLines: maxLines,
  )..layout(maxWidth: maxWidth);
  try {
    if (whole.didExceedMaxLines || whole.height > maxHeight) return false;
    // A word that does not fit [maxWidth] breaks across lines, which the
    // line count above does not show when lines are left over.
    for (final word in text.split(' ')) {
      if (measureTextWidth(context, word, style) > maxWidth) return false;
    }
    return true;
  } finally {
    whole.dispose();
  }
}

/// The span of `Text(text, style: style)`: the Bold Text setting is merged
/// into [style] and wins over its font weight.
TextSpan _plainSpan(BuildContext context, String text, TextStyle? style) =>
    TextSpan(
      text: text,
      style: MediaQuery.boldTextOf(context)
          ? style?.copyWith(fontWeight: FontWeight.bold)
          : style,
    );

TextPainter _painter(
  BuildContext context,
  InlineSpan span, {
  required int maxLines,
}) {
  // As `Text` does: the Bold Text setting makes the style bold.
  final boldText = MediaQuery.boldTextOf(context);
  final base = DefaultTextStyle.of(context).style;
  final styled = TextSpan(
    style: boldText ? base.copyWith(fontWeight: FontWeight.bold) : base,
    children: [span],
  );
  return TextPainter(
    text: styled,
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: maxLines,
  );
}
