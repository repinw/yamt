import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';
import 'package:yamt/features/cooking/presentation/models/cook_view.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_line_row.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_step_frame.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Im Vorrat gefunden": each line with a Vorrat suggestion, to accept with
/// ✓ or turn down with ✕. A tap on the items picks others.
class CookFoundStep extends StatelessWidget {
  /// Creates the step.
  const new({
    required this.view,
    required this.onAccept,
    required this.onReject,
    required this.onReopen,
    required this.onPick,
    required this.onNext,
    super.key,
  });

  /// Key of the ✓ of the line [lineId].
  static ValueKey<String> acceptKey(String lineId) =>
      ValueKey('cook-accept-$lineId');

  /// Key of the ✕ of the line [lineId].
  static ValueKey<String> rejectKey(String lineId) =>
      ValueKey('cook-reject-$lineId');

  /// The cooking.
  final CookView view;

  /// Accepts the suggestion of a line.
  final ValueChanged<CookLineView> onAccept;

  /// Turns the suggestion of a line down.
  final ValueChanged<CookLineView> onReject;

  /// Undoes ✓ or ✕ of a line.
  final ValueChanged<CookLineView> onReopen;

  /// Opens the item picker of a line.
  final ValueChanged<CookLineView> onPick;

  /// Goes on.
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lines = view.foundLines;
    final unchecked = lines
        .where((line) => line.clarification is LineOpen)
        .length;
    return CookStepFrame(
      kicker: l10n.cookFoundKicker(lines.length, view.lines.length),
      title: l10n.cookFoundTitle,
      hint: l10n.cookFoundHint,
      buttonLabel: unchecked > 0
          ? l10n.cookCheckRest(unchecked)
          : l10n.cookNext,
      onButton: unchecked > 0 ? null : onNext,
      children: [
        for (final line in lines)
          CookLineRow(
            key: ValueKey(line.line.id),
            line: line,
            onItems: () => onPick(line),
            trailing: _Choice(
              line: line,
              onAccept: onAccept,
              onReject: onReject,
              onReopen: onReopen,
            ),
          ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const new({
    required this.line,
    required this.onAccept,
    required this.onReject,
    required this.onReopen,
  });

  final CookLineView line;
  final ValueChanged<CookLineView> onAccept;
  final ValueChanged<CookLineView> onReject;
  final ValueChanged<CookLineView> onReopen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accepted = line.clarification is LineAssigned;
    final rejected = line.clarification is LineRejected;
    final id = line.line.id;
    ButtonStyle style({required bool on, required Color color}) =>
        IconButton.styleFrom(
          backgroundColor: on ? color : null,
          foregroundColor: on ? scheme.surface : colors.muted,
          side: on ? null : BorderSide(color: colors.rule),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: CookFoundStep.rejectKey(id),
          tooltip: l10n.cookFitsNot,
          style: style(on: rejected, color: scheme.error),
          onPressed: () => rejected ? onReopen(line) : onReject(line),
          icon: const Icon(Icons.close_rounded),
        ),
        IconButton(
          key: CookFoundStep.acceptKey(id),
          tooltip: l10n.cookFits,
          style: style(on: accepted, color: colors.ink),
          onPressed: () => accepted ? onReopen(line) : onAccept(line),
          icon: const Icon(Icons.check_rounded),
        ),
      ],
    );
  }
}
