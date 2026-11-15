import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What the cook answers for one line.
enum KochmodusChange {
  /// "Hab ich": the food is at home, in the Vorrat or found by search.
  have,

  /// "Kaufen": the line goes on the shopping list.
  shop,

  /// "Weglassen": the line is left out.
  ignore,
}

/// "Zutat ändern" of a line, or "Was hast du da?" while it is open: each
/// answer once, with one plain line. It pops with the answer, or `null` when
/// it is closed.
class KochmodusChangeSheet extends StatelessWidget {
  /// Creates the sheet [title] for the line [line] with [answers].
  const new({
    required this.title,
    required this.line,
    required this.answers,
    super.key,
  });

  /// Key of the answer [answer].
  static ValueKey<String> answerKey(KochmodusChange answer) =>
      ValueKey<String>('kochmodus-change-${answer.name}');

  /// The question, such as "Zutat ändern".
  final String title;

  /// The line as it is cooked, such as "250 g Mehl".
  final String line;

  /// The answers that change something, in their order.
  final List<KochmodusChange> answers;

  /// Shows the sheet and returns the answer.
  static Future<KochmodusChange?> show(
    BuildContext context, {
    required String title,
    required String line,
    required List<KochmodusChange> answers,
  }) => showModalBottomSheet<KochmodusChange>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: FoodLabelColors.of(context).card,
    builder: (_) =>
        KochmodusChangeSheet(title: title, line: line, answers: answers),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            title,
            style: textTheme.titleLarge?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final answer in answers)
            ListTile(
              key: answerKey(answer),
              contentPadding: EdgeInsets.zero,
              title: Text(switch (answer) {
                KochmodusChange.have => l10n.kochmodusAssignHave,
                KochmodusChange.shop => l10n.kochmodusAssignShop,
                KochmodusChange.ignore => l10n.kochmodusAssignIgnore,
              }),
              subtitle: Text(switch (answer) {
                KochmodusChange.have => l10n.kochmodusChangeHaveSub,
                KochmodusChange.shop => l10n.kochmodusAssignPendingShopping,
                KochmodusChange.ignore => l10n.kochmodusChangeIgnoreSub,
              }),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).pop(answer),
            ),
        ],
      ),
    );
  }
}
