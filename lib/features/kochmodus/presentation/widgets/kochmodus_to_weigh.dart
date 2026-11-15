import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Noch zu wiegen" on "Kochen", under every step of the guide and on the
/// cooking list: one chip per line whose weight is missing or only a guess,
/// such as "1 Zwiebel" or "2 EL Öl" from a food kept in grams or ml
/// (`KochmodusView.toWeigh`); a food with its own piece weight, such as
/// eggs, gets none. A tap opens the keypad. A weighed line drops off by
/// itself.
class KochmodusToWeigh extends StatelessWidget {
  /// Creates the section of [lines] for the cooking of [target].
  const new({required this.target, required this.lines, super.key});

  /// Key of the chip of the line [lineId].
  static ValueKey<String> chipKey(String lineId) =>
      ValueKey<String>('kochmodus-to-weigh-$lineId');

  /// What the page cooks; actions go to its controller.
  final KochmodusTarget target;

  /// The lines still to weigh (`KochmodusView.toWeigh`); the page hides
  /// the section without any.
  final List<KochmodusLineView> lines;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xs,
      children: [
        Text(
          AppLocalizations.of(context)!.kochmodusToWeigh,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: colors.muted),
        ),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final line in lines)
              ActionChip(
                key: chipKey(line.id),
                avatar: const Icon(Icons.scale_outlined),
                label: Text(line.text, overflow: TextOverflow.ellipsis),
                onPressed: () =>
                    unawaited(KochmodusActionFlow.weigh(context, target, line)),
              ),
          ],
        ),
      ],
    );
  }
}
