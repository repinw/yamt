import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/utils/text_measure.dart';
import 'package:yamt/features/diary/presentation/models/diary_macro_tile_view.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_number.dart';

/// Text style of a macro's name or letter, without its color.
TextStyle? diaryMacroNameStyle(BuildContext context) =>
    Theme.of(context).textTheme.labelLarge
        ?.copyWith(fontFamily: AppFonts.geist, fontWeight: FontWeight.w700);

/// The names of [macros], all of them full or all of them letters: the
/// letters where [allowFull] is false and, at large text, where a full name
/// would not fit [maxWidth] whole. At the default text size a full name that
/// is too long ends with an ellipsis.
List<String> diaryMacroNames(
  BuildContext context,
  List<DiaryMacroTileView> macros, {
  required double maxWidth,
  required TextStyle? style,
  required bool allowFull,
}) {
  final full =
      allowFull &&
      (!isLargeText(context) ||
          macros.every(
            (macro) => textFitsWholeWords(
              context,
              macro.label,
              style,
              maxWidth: maxWidth,
            ),
          ));
  return [
    for (final macro in macros)
      if (full) macro.label else macro.letter,
  ];
}

/// Width of the widest of [names] in the name style at large text, so the
/// names of a tile share one width; 0 at the default text size, where each
/// name takes its own.
double diaryMacroNameWidth(BuildContext context, List<String> names) {
  if (!isLargeText(context)) return 0;
  final style = diaryMacroNameStyle(context);
  return names
      .map((name) => measureTextWidth(context, name, style))
      .fold<double>(0, math.max);
}

/// The size that the grams of [macros] share at large text, to give each
/// [DiaryMacroValue]; null at the default text size.
double? diaryMacroValueWidth(
  BuildContext context,
  List<DiaryMacroTileView> macros,
) => DiaryTileNumber.sharedWidthOf(context, [
  for (final macro in macros) macro.value,
], compact: true);

/// Name or letter of a macro in its color.
class DiaryMacroName extends StatelessWidget {
  /// Creates the name [text] in [color]; a screen reader says [label].
  const new(this.text, {required this.label, required this.color, super.key});

  /// Name or letter.
  final String text;

  /// Full name, which a screen reader says also where only the letter shows.
  final String label;

  /// Color of the name.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      semanticsLabel: label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: diaryMacroNameStyle(context)?.copyWith(color: color),
    );
  }
}

/// Grams of a macro; at large text shrunk to the size the longest of the
/// macros needs, or dropped where that is too small to read.
class DiaryMacroValue extends StatelessWidget {
  /// Creates the grams of [macro].
  const new(
    this.macro, {
    required this.sharedWidth,
    this.alignment = AlignmentDirectional.centerEnd,
    super.key,
  });

  /// The macro.
  final DiaryMacroTileView macro;

  /// The shared size of the tile's grams, from [diaryMacroValueWidth].
  final double? sharedWidth;

  /// Where the grams sit when they are smaller than their room.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => DiaryTileNumber(
    macro.value,
    sharedWidth: sharedWidth,
    color: macro.valueColor,
    compact: true,
    minScale: AppDashboard.macroValueMinScale,
    alignment: alignment,
  );
}
