import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Gerade dazu" in the Kochhelfer: what the microphone hears, or what the
/// cook just said or typed with a button that takes it back. Shows nothing
/// before the first addition.
class CookingGuideJustAdded extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.justAdded,
    required this.onUndo,
    this.pending,
    super.key,
  });

  /// Key of "Rückgängig".
  static const undoKey = ValueKey<String>('cooking-guide-undo');

  /// The ingredients that the cook added last.
  final List<String> justAdded;

  /// What the microphone hears before it is final.
  final String? pending;

  /// Takes [justAdded] out again; `null` turns the button off.
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final pending = this.pending;
    final added = pending ?? justAdded.join(' · ');
    if (added.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colors.ink,
              width: AppGraphit.highlightUnderline,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.cookingGuideJustAdded.toUpperCase(),
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.accentText,
                        letterSpacing: AppGraphit.kickerTracking,
                      ),
                    ),
                    Text(
                      added,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: pending == null ? colors.ink : colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (pending == null)
                FilledButton.tonal(
                  key: undoKey,
                  onPressed: onUndo,
                  child: Text(l10n.commonUndoAction),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
