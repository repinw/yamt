import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Eaten and target when [showTotal], otherwise what is left, or the overage
/// in the error color.
class DiaryMacroStripAmountText extends StatelessWidget {
  /// Creates the widget.
  const new({
    required this.current,
    required this.target,
    required this.showTotal,
    required this.format,
    required this.style,
    super.key,
    this.suffix = '',
  });

  /// Amount eaten.
  final double current;

  /// Target amount.
  final double target;

  /// Whether eaten and target are shown instead of what is left.
  final bool showTotal;

  /// Locale-aware number formatter.
  final NumberFormat format;

  /// Text style of the amount.
  final TextStyle? style;

  /// Unit glued to the left amount, e.g. "g". The kcal row has its own label.
  final String suffix;

  @override
  Widget build(BuildContext context) {
    if (showTotal) {
      return Text(
        '${format.format(current.round())} / ${format.format(target.round())}',
        maxLines: 1,
        style: style,
      );
    }
    final l10n = AppLocalizations.of(context)!;
    final left = (target - current).round();
    if (left < 0) {
      return Text(
        l10n.diaryAmountOver('${format.format(-left)}$suffix'),
        maxLines: 1,
        style: style?.copyWith(color: Theme.of(context).colorScheme.error),
      );
    }
    return Text(
      l10n.diaryAmountLeft('${format.format(left)}$suffix'),
      maxLines: 1,
      style: style,
    );
  }
}
