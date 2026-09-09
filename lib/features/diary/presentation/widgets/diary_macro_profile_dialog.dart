import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/diary/domain/diary_macro_profile.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Dialog showing macro distribution percentages and an explanation.
class DiaryMacroProfileDialog extends StatelessWidget {
  /// Creates a macro profile dialog.
  const DiaryMacroProfileDialog({
    required this.profile,
    required this.numberFormat,
    super.key,
  });

  /// The macro profile whose shares are displayed.
  final DiaryMacroProfile profile;

  /// Formatter for percentage values.
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = diaryMacroEmphasisLabel(l10n, profile.emphasis);
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Text(
          '${l10n.caloriesProteinLabel}: '
          '${numberFormat.format(profile.protein * 100)} %\n'
          '${l10n.caloriesCarbsLabel}: '
          '${numberFormat.format(profile.carbs * 100)} %\n'
          '${l10n.caloriesFatLabel}: '
          '${numberFormat.format(profile.fat * 100)} %\n\n'
          '${l10n.diaryMacroProfileExplanation}',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            MaterialLocalizations.of(context).closeButtonLabel,
          ),
        ),
      ],
    );
  }
}

/// Localized label for a [DiaryMacroEmphasis].
String diaryMacroEmphasisLabel(
  AppLocalizations l10n,
  DiaryMacroEmphasis emphasis,
) =>
    switch (emphasis) {
      DiaryMacroEmphasis.protein => l10n.diaryMacroProteinEmphasis,
      DiaryMacroEmphasis.carbs => l10n.diaryMacroCarbsEmphasis,
      DiaryMacroEmphasis.fat => l10n.diaryMacroFatEmphasis,
      DiaryMacroEmphasis.mixed => l10n.diaryMacroMixedEmphasis,
    };
