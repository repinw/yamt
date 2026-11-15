import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_step_foot.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Wiegen": a keypad for the grams on the scale, with a key that takes
/// the [hint] when there is one. With [estimate] it changes an estimate
/// instead ("Schätzung ändern").
class KochmodusWeighSheet extends StatefulWidget {
  /// Creates the sheet.
  const new({
    required this.title,
    required this.sub,
    required this.hint,
    required this.estimate,
    super.key,
  });

  /// Key of the confirm button.
  static const confirmKey = ValueKey<String>('kochmodus-weigh-confirm');

  /// Key of the key that takes the hint.
  static const hintKey = ValueKey<String>('kochmodus-weigh-hint');

  /// Key of the key for [digit].
  static ValueKey<String> digitKey(int digit) =>
      ValueKey<String>('kochmodus-weigh-$digit');

  // A scale shows at most 99999 g.
  static const _maxDigits = 5;

  /// What is weighed, such as "2 Zwiebeln" or the pot's name.
  final String title;

  /// A line below [title], such as "Zwiebeln rot · Rezept etwa 160 g".
  final String? sub;

  /// The grams the hint key takes, such as the recipe's estimate; `null`
  /// leaves that key empty (pots).
  final int? hint;

  /// Whether the sheet changes an estimate instead of a weighing.
  final bool estimate;

  /// Shows the sheet and returns the grams, or `null` when it is closed.
  static Future<int?> show(
    BuildContext context, {
    required String title,
    String? sub,
    int? hint,
    bool estimate = false,
  }) => showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (_) => KochmodusWeighSheet(
      title: title,
      sub: sub,
      hint: hint,
      estimate: estimate,
    ),
  );

  @override
  State<KochmodusWeighSheet> createState() => _KochmodusWeighSheetState();
}

class _KochmodusWeighSheetState extends State<KochmodusWeighSheet> {
  String _value = '';

  void _press(int digit) {
    if (_value.length >= KochmodusWeighSheet._maxDigits) return;
    setState(() => _value = '$_value$digit'.replaceFirst(RegExp('^0+'), ''));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final hint = widget.hint;
    final sub = widget.sub;
    final grams = int.tryParse(_value) ?? 0;
    Widget row(List<int> digits) => Row(
      children: [
        for (final digit in digits)
          _KeypadKey(
            key: KochmodusWeighSheet.digitKey(digit),
            onTap: () => _press(digit),
            child: Text('$digit', style: textTheme.titleLarge),
          ),
      ],
    );
    return SafeArea(
      child: Padding(
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
            Text(
              (widget.estimate
                      ? l10n.kochmodusEstimateKicker
                      : l10n.kochmodusWeigh)
                  .toUpperCase(),
              style: textTheme.labelMedium?.copyWith(
                color: colors.muted,
                letterSpacing: AppGraphit.kickerTracking,
              ),
            ),
            Text(
              widget.title,
              style: textTheme.titleLarge?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (sub != null)
              Text(
                sub,
                style: textTheme.bodySmall?.copyWith(color: colors.muted),
              ),
            Center(
              child: Text(
                l10n.cookAmountGrams('$grams'),
                style: textTheme.displaySmall?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            row(const [1, 2, 3]),
            row(const [4, 5, 6]),
            row(const [7, 8, 9]),
            Row(
              children: [
                _KeypadKey(
                  key: KochmodusWeighSheet.hintKey,
                  onTap: hint == null
                      ? null
                      : () => setState(() => _value = '$hint'),
                  child: Text(
                    hint == null ? '' : l10n.cookAmountGrams('$hint'),
                    style: textTheme.labelLarge,
                  ),
                ),
                _KeypadKey(
                  key: KochmodusWeighSheet.digitKey(0),
                  onTap: () => _press(0),
                  child: Text('0', style: textTheme.titleLarge),
                ),
                _KeypadKey(
                  onTap: _value.isEmpty
                      ? null
                      : () => setState(
                          () => _value = _value.substring(0, _value.length - 1),
                        ),
                  child: Icon(
                    Icons.backspace_outlined,
                    semanticLabel: MaterialLocalizations.of(context)
                        .deleteButtonTooltip,
                  ),
                ),
              ],
            ),
            FilledButton(
              key: KochmodusWeighSheet.confirmKey,
              onPressed: _value.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(grams),
              style: KochmodusStepFoot.mainButtonStyle(context),
              child: Text(
                widget.estimate
                    ? l10n.kochmodusEstimateConfirm(grams)
                    : l10n.kochmodusWeighConfirm(grams),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const new({required this.onTap, required this.child, super.key});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      child: FilledButton.tonal(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppGraphit.toolButton),
        ),
        child: child,
      ),
    ),
  );
}
