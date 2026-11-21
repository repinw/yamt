import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Font sizes of the tab words and the action word, and the line height
/// that the bar reserves for them: the scaled one, so the bar grows with
/// large text even when the words shrink.
typedef HomeNavLabelSizes = ({double tab, double action, double height});

/// Style of a word in the home bar at the final [fontSize]: the system text
/// scale is already in it.
TextStyle? homeNavLabelStyle(
  BuildContext context,
  Color color, {
  required FontWeight weight,
  required double fontSize,
}) {
  return Theme.of(context).textTheme.labelSmall
      ?.copyWith(color: color, fontSize: fontSize, fontWeight: weight);
}

double _lineHeight(BuildContext context, double size) {
  final painter = TextPainter(
    text: TextSpan(
      text: ' ',
      style: homeNavLabelStyle(
        context,
        Colors.transparent,
        weight: FontWeight.w600,
        fontSize: size,
      ),
    ),
    textDirection: Directionality.of(context),
  )..layout();
  final height = painter.height;
  painter.dispose();
  return height;
}

/// Room that a word keeps beyond its gap, against rounding.
const double _fitSlack = 0.01;
const double _fitShrink = 0.98;
const int _fitSteps = 20;
const double _leastFontSize = 1;

double _wordWidth(
  BuildContext context,
  String word,
  FontWeight weight,
  double size,
) {
  final painter = TextPainter(
    text: TextSpan(
      text: word,
      style: homeNavLabelStyle(
        context,
        Colors.transparent,
        weight: weight,
        fontSize: size,
      ),
    ),
    textDirection: Directionality.of(context),
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// The largest size up to [size] at which every word is at most [width] wide.
///
/// The width of a word is not proportional to the size, because the style
/// carries a fixed letter spacing. So the size is solved from two
/// measurements and then checked against a measurement at the result.
double _fittingSize(
  BuildContext context,
  List<String> words, {
  required FontWeight weight,
  required double size,
  required double width,
}) {
  final room = width - _fitSlack;
  var fitting = size;
  for (final word in words) {
    double measure(double at) => _wordWidth(context, word, weight, at);
    final full = measure(size);
    if (full <= room) {
      continue;
    }
    final half = size / 2;
    final slope = (full - measure(half)) / (size - half);
    var candidate = (room - (full - slope * size)) / slope;
    for (var i = 0; i < _fitSteps && measure(candidate) > room; i += 1) {
      candidate *= _fitShrink;
    }
    fitting = math.min(fitting, math.max(candidate, _leastFontSize));
  }
  return fitting;
}

/// The sizes of the words in the home bottom bar when it is [width] wide
/// with the tab [words] and the [actionWord].
///
/// The tab words share the largest size at which each fits its tab with
/// [AppGraphit.navWordGap] on each side, measured with the selected weight
/// so that switching tabs changes no size. The action word is never larger.
HomeNavLabelSizes homeNavLabelSizes(
  BuildContext context, {
  required double width,
  required List<String> words,
  required String actionWord,
}) {
  final tabWidth =
      (width -
          2 * AppSpacing.lg -
          AppSpacing.xs -
          AppGraphit.navActionWidth -
          2 * AppGraphit.navCapsulePadding) /
      words.length;
  final natural = MediaQuery.textScalerOf(context)
      .scale(AppFontSizes.homeBottomNavLabel);
  final tab = _fittingSize(
    context,
    words,
    weight: FontWeight.w600,
    size: natural,
    width: tabWidth - 2 * AppGraphit.navWordGap,
  );
  final action = _fittingSize(
    context,
    [actionWord],
    weight: FontWeight.w700,
    size: tab,
    width: AppGraphit.navActionWidth - 2 * AppGraphit.navWordGap,
  );
  return (tab: tab, action: action, height: _lineHeight(context, natural));
}
