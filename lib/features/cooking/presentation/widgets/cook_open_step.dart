import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';
import 'package:yamt/features/cooking/presentation/models/cook_view.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_line_row.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_step_frame.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Noch zu klären": the lines without an accepted suggestion, each to
/// assign from the Vorrat or to leave out.
class CookOpenStep extends StatelessWidget {
  /// Creates the step.
  const new({
    required this.view,
    required this.onAssign,
    required this.onOmit,
    required this.onNext,
    super.key,
  });

  /// Key of "Zuordnen" of the line [lineId].
  static ValueKey<String> assignKey(String lineId) =>
      ValueKey('cook-assign-$lineId');

  /// Key of "Weglassen" of the line [lineId].
  static ValueKey<String> omitKey(String lineId) =>
      ValueKey('cook-omit-$lineId');

  /// The cooking.
  final CookView view;

  /// Opens the item picker of a line.
  final ValueChanged<CookLineView> onAssign;

  /// Leaves a line out.
  final ValueChanged<CookLineView> onOmit;

  /// Goes on.
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lines = view.openLines;
    final settled = lines.every(
      (line) =>
          line.clarification is LineAssigned ||
          line.clarification is LineOmitted,
    );
    return CookStepFrame(
      kicker: l10n.cookOpenKicker(lines.length),
      title: l10n.cookOpenTitle,
      hint: l10n.cookOpenHint,
      buttonLabel: l10n.cookNext,
      onButton: settled ? onNext : null,
      children: [
        for (final line in lines)
          CookLineRow(
            key: ValueKey(line.line.id),
            line: line,
            state: switch (line.clarification) {
              LineAssigned() => null,
              LineOmitted() => l10n.cookOpenOmitted,
              LineRejected() => l10n.cookOpenRejected,
              LineOpen() => l10n.cookOpenNoItem,
            },
            below: Padding(
              padding: const EdgeInsets.only(
                left: AppGraphit.letterTile + AppSpacing.md,
              ),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _ChoiceButton(
                    key: assignKey(line.line.id),
                    label: l10n.cookAssign,
                    selected: line.clarification is LineAssigned,
                    onPressed: () => onAssign(line),
                  ),
                  _ChoiceButton(
                    key: omitKey(line.line.id),
                    label: l10n.cookOmit,
                    selected: line.clarification is LineOmitted,
                    onPressed: () => onOmit(line),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => selected
      ? FilledButton(onPressed: onPressed, child: Text(label))
      : OutlinedButton(onPressed: onPressed, child: Text(label));
}
