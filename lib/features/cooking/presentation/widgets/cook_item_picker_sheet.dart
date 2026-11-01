import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/cooking/application/stock_suggestion.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';
import 'package:yamt/features/cooking/domain/stock_fill.dart';
import 'package:yamt/features/cooking/presentation/models/cook_view.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_amount_text.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Lets the cook tap the Vorrat items for [line] in order: each gives what
/// it has, the last one fills the rest. Returns the takes, or `null` when
/// the sheet closes without "Übernehmen".
Future<List<ItemTake>?> showCookItemPicker({
  required BuildContext context,
  required CookLineView line,
}) => showModalBottomSheet<List<ItemTake>>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _CookItemPicker(line: line),
);

class _CookItemPicker extends StatefulWidget {
  const new({required this.line});

  final CookLineView line;

  @override
  State<_CookItemPicker> createState() => _CookItemPickerState();
}

class _CookItemPickerState extends State<_CookItemPicker> {
  // Whether the items whose name does not fit are shown, at once when one
  // of them is picked.
  late bool _showAll = widget.line.takes.any(
    (take) =>
        widget.line.offers.every((offer) => offer.item.id != take.item.id),
  );

  late final List<String> _picked = [
    for (final take in widget.line.takes) take.item.id,
  ];

  // The picked offers that share the first one's unit and scale, in pick
  // order.
  List<CookOffer> get _chosen {
    final byId = {
      for (final offer in [...widget.line.offers, ...widget.line.moreOffers])
        offer.item.id: offer,
    };
    final picked = [for (final id in _picked) ?byId[id]];
    final first = picked.firstOrNull?.item;
    return [
      for (final offer in picked)
        if (offer.item.amountUnit == first?.amountUnit &&
            cookAmountScale(offer.item) == cookAmountScale(first!))
          offer,
    ];
  }

  List<ItemTake> get _takes {
    final chosen = _chosen;
    return fillInOrder(
      needed: chosen.firstOrNull?.needed ?? 0,
      offers: [
        for (final offer in chosen)
          (itemId: offer.item.id, available: offer.available),
      ],
    );
  }

  // A line without amount takes one item, so a pick replaces the last.
  void _toggle(String itemId) => setState(() {
    if (_picked.remove(itemId)) return;
    if ((widget.line.needed ?? 0) <= 0) _picked.clear();
    _picked.add(itemId);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final takes = _takes;
    final first = _chosen.firstOrNull;
    final need = first?.needed ?? widget.line.needed ?? 0;
    final unit = first?.item.amountUnit ?? widget.line.unit;
    final scale = first == null
        ? widget.line.scale
        : cookAmountScale(first.item);
    final amountById = {for (final take in takes) take.itemId: take.amount};
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
          spacing: AppSpacing.xs,
          children: [
            Text(
              l10n.cookPickerKicker.toUpperCase(),
              style: textTheme.labelMedium?.copyWith(
                color: colors.muted,
                letterSpacing: AppGraphit.kickerTracking,
              ),
            ),
            Text(
              widget.line.label,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              widget.line.offers.isEmpty
                  ? l10n.cookPickerEmpty
                  : l10n.cookPickerHint,
              style: textTheme.labelMedium?.copyWith(color: colors.muted),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final offer in [
                    ...widget.line.offers,
                    if (_showAll) ...widget.line.moreOffers,
                  ])
                    _OfferRow(
                      offer: offer,
                      number: _picked.indexOf(offer.item.id) + 1,
                      amount: amountById[offer.item.id],
                      onTap: () => _toggle(offer.item.id),
                    ),
                  if (!_showAll && widget.line.moreOffers.isNotEmpty)
                    TextButton(
                      key: const ValueKey('cook-picker-show-all'),
                      onPressed: () => setState(() => _showAll = true),
                      child: Text(l10n.cookPickerShowAll),
                    ),
                ],
              ),
            ),
            if (_picked.isNotEmpty && need > 0)
              ColoredBox(
                color: colors.ink,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Text(
                    l10n.cookPickerSum(
                      cookAmountText(
                        l10n,
                        takenAmount(takes),
                        unit,
                        scale: scale,
                      ),
                      cookAmountText(l10n, need, unit, scale: scale),
                    ),
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.paper,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            FilledButton(
              onPressed: takes.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(takes),
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.onAccent,
                minimumSize: const Size.fromHeight(AppGraphit.buttonHeight),
              ),
              child: Text(l10n.cookPickerApply),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferRow extends StatelessWidget {
  const new({
    required this.offer,
    required this.number,
    required this.amount,
    required this.onTap,
  });

  final CookOffer offer;

  // The pick position from 1, or 0 when not picked.
  final int number;

  // What the item gives, `null` when it gives nothing.
  final int? amount;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final item = offer.item;
    final amount = this.amount;
    return AppInkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppGraphit.rowTile + AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.rule)),
        ),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            CircleAvatar(
              radius: AppGraphit.chipIcon,
              backgroundColor: number > 0 ? colors.ink : colors.rule,
              foregroundColor: colors.paper,
              child: number > 0 ? Text('$number') : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l10n.cookStockLeft(
                      cookItemAmount(l10n, item, offer.available),
                    ),
                    style: textTheme.bodySmall?.copyWith(color: colors.muted),
                  ),
                ],
              ),
            ),
            if (amount != null && amount > 0)
              Text(
                cookItemAmount(l10n, item, amount),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
