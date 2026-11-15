import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_card_answers.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What the cook answers to "Wie viel nimmst du?".
enum KochmodusTakeAnswer {
  /// The recipe's amount ("400 g · wie im Rezept"), also when the cook set
  /// an own amount before; on a line whose text names no amount, the line's
  /// own ("450 g").
  recipe,

  /// All the food has for the line ("Alles · 500 g").
  all,

  /// Another amount ("Andere Menge"), typed on the amount sheet.
  other,
}

/// "Wie viel nimmst du?" once the cook picked a Vorrat food that holds a bit
/// more than the line needs: the line, the question, the food with what it
/// has, and the answers. It pops with the answer, or `null` when it is
/// closed. It scrolls when the text is large.
class KochmodusTakeSheet extends StatelessWidget {
  /// Creates the sheet for the line [line] and the food [food].
  const new({
    required this.line,
    required this.food,
    required this.keep,
    required this.fromRecipe,
    required this.all,
    super.key,
  });

  /// Key of the answer [answer].
  static ValueKey<String> answerKey(KochmodusTakeAnswer answer) =>
      ValueKey<String>('kochmodus-take-${answer.name}');

  /// The line as it is cooked, such as "400 g Hähnchenbrust".
  final String line;

  /// The food with what it has, such as "Hähnchenbrustfilet · 500 g da".
  final String food;

  /// What the line takes, such as "400 g".
  final String keep;

  /// Whether [keep] is the recipe's amount ("400 g · wie im Rezept"), not the
  /// cook's own on a line whose text names none ("450 g").
  final bool fromRecipe;

  /// All the food has for the line, such as "500 g".
  final String all;

  /// Shows the sheet and returns the answer.
  static Future<KochmodusTakeAnswer?> show(
    BuildContext context, {
    required String line,
    required String food,
    required String keep,
    required bool fromRecipe,
    required String all,
  }) => showModalBottomSheet<KochmodusTakeAnswer>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: FoodLabelColors.of(context).card,
    builder: (_) => KochmodusTakeSheet(
      line: line,
      food: food,
      keep: keep,
      fromRecipe: fromRecipe,
      all: all,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    void answer(KochmodusTakeAnswer take) => Navigator.of(context).pop(take);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                line.toUpperCase(),
                style: textTheme.labelMedium?.copyWith(
                  color: colors.muted,
                  letterSpacing: AppGraphit.kickerTracking,
                ),
              ),
              Text(
                l10n.kochmodusTakeAskTitle,
                style: textTheme.titleLarge?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                food,
                style: textTheme.bodyMedium?.copyWith(color: colors.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          FilledButton(
            key: answerKey(KochmodusTakeAnswer.recipe),
            onPressed: () => answer(KochmodusTakeAnswer.recipe),
            style: KochmodusCardAnswers.mainStyle(context),
            child: Text(
              fromRecipe ? l10n.kochmodusTakeAskRecipe(keep) : keep,
              textAlign: TextAlign.center,
            ),
          ),
          FilledButton.tonal(
            key: answerKey(KochmodusTakeAnswer.all),
            onPressed: () => answer(KochmodusTakeAnswer.all),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(AppGraphit.buttonHeight),
            ),
            child: Text(
              l10n.kochmodusTakeAskAll(all),
              textAlign: TextAlign.center,
            ),
          ),
          TextButton(
            key: answerKey(KochmodusTakeAnswer.other),
            onPressed: () => answer(KochmodusTakeAnswer.other),
            child: Text(l10n.kochmodusTakeAskOther),
          ),
        ],
      ),
    );
  }
}
