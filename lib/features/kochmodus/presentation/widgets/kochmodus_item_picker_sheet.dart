import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_sort_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_picker_offers.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_group_title.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_picker_item_row.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_picker_parts.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Welches nimmst du?" for one line: the Vorrat rows with their stock, what
/// is "verplant" and what "fehlt". A tap takes a food: once the tapped foods
/// cover the line's need the picker closes with them, in the order tapped;
/// until then it says what is still missing ("Es fehlen noch 200 ml") and
/// offers "So lassen" beside another tap. The whole Vorrat shows at once: the
/// foods whose name resembles the line under "Passt vielleicht", then every
/// other food under "Alles im Vorrat" in the Vorrat's order and receipts
/// (without a suggestion only these, without the title); only a suggestion
/// says what it lacks. The search looks through all. The cook picks: nothing
/// is chosen for him. "Etwas anderes suchen" stays in sight under the list and
/// pops an empty list: the caller opens the search.
class KochmodusItemPickerSheet extends StatefulWidget {
  /// Creates the picker for the line [title] that needs [need] with
  /// [offers], the items in [picked] tapped already; [holders] names the
  /// other runs that take from them.
  const new({
    required this.title,
    required this.need,
    required this.offers,
    required this.picked,
    this.holders = const {},
    super.key,
  });

  /// Key of "So lassen".
  static const keepKey = ValueKey<String>('kochmodus-picker-keep');

  /// Key of "Nur N nehmen" when the tapped foods hold too little.
  static const takeOnlyKey = ValueKey<String>('kochmodus-picker-take-only');

  /// Key of "N kaufen" when the tapped foods hold too little.
  static const buyRestKey = ValueKey<String>('kochmodus-picker-buy-rest');

  /// Key of the line that says what is still missing.
  static const missingKey = ValueKey<String>('kochmodus-picker-missing');

  /// Key of the title "Passt vielleicht".
  static const suggestedKey = ValueKey<String>('kochmodus-picker-suggested');

  /// Key of the title "Alles im Vorrat".
  static const allKey = ValueKey<String>('kochmodus-picker-all');

  /// Key of the search field.
  static const searchKey = ValueKey<String>('kochmodus-picker-search');

  /// Key of "Etwas anderes suchen".
  static const searchOtherKey = ValueKey<String>('kochmodus-picker-other');

  /// Key of the header of the receipt group [groupKey].
  static ValueKey<String> receiptKey(String groupKey) =>
      ValueKey<String>('kochmodus-picker-receipt-$groupKey');

  /// Key of the row of the item [itemId].
  static ValueKey<String> rowKey(String itemId) =>
      ValueKey<String>('kochmodus-picker-$itemId');

  /// The line as it is cooked, such as "750 g Hack", above the question.
  final String title;

  /// What the line needs, `null` without an amount: any food covers it.
  final TemplateIngredientRequirement? need;

  /// The items the picker offers.
  final KochmodusPickerOffers offers;

  /// The ids of the items the line takes now, in their order.
  final List<String> picked;

  /// The name of another run that takes something of an item, by item id.
  final Map<String, String> holders;

  /// Shows the picker and returns the tapped items with the cook's answer
  /// ([KochmodusPickerResult]), no ids for "Etwas anderes suchen", or `null`
  /// when it closes without either.
  static Future<KochmodusPickerResult?> show(
    BuildContext context, {
    required String title,
    required TemplateIngredientRequirement? need,
    required KochmodusPickerOffers offers,
    required List<String> picked,
    Map<String, String> holders = const {},
  }) => showModalBottomSheet<KochmodusPickerResult>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: FoodLabelColors.of(context).card,
    builder: (_) => KochmodusItemPickerSheet(
      title: title,
      need: need,
      offers: offers,
      picked: picked,
      holders: holders,
    ),
  );

  @override
  State<KochmodusItemPickerSheet> createState() =>
      _KochmodusItemPickerSheetState();
}

class _KochmodusItemPickerSheetState extends State<KochmodusItemPickerSheet> {
  late final Set<String> _matches = {
    for (final offer in widget.offers.matches) offer.item.id,
  };

  late final Map<String, KochmodusOffer> _offered = {
    for (final offer in [...widget.offers.matches, ...widget.offers.rest])
      offer.item.id: offer,
  };

  // The line's items that are still in the Vorrat stay tapped.
  late final List<String> _picked = [
    for (final id in widget.picked)
      if (_offered.containsKey(id)) id,
  ];

  int get _missing => kochmodusPickerStillMissing([
    for (final id in _picked) ?_offered[id],
  ], widget.need);

  var _query = '';

  void _close(KochmodusPickerShort short) =>
      Navigator.of(context)
          .pop<KochmodusPickerResult>((ids: List.of(_picked), short: short));

  // A tap takes the food, or gives a tapped one back; the picker closes once
  // the taken foods cover the line.
  void _toggle(String itemId) {
    final taken = !_picked.remove(itemId);
    if (taken) _picked.add(itemId);
    if (taken && _missing == 0) {
      _close(KochmodusPickerShort.keep);
      return;
    }
    setState(() {});
  }

  Widget _rows(List<KochmodusPickerRow> rows) => SliverList.builder(
    itemCount: rows.length,
    itemBuilder: (context, index) => switch (rows[index]) {
      KochmodusPickerReceiptRow(:final group) => KochmodusGroupTitle(
        key: KochmodusItemPickerSheet.receiptKey(group.key),
        title: group.title(
          l10n: AppLocalizations.of(context)!,
          dateFormat: DateFormat.yMMMd(
            Localizations.localeOf(context).toLanguageTag(),
          ),
        ),
      ),
      KochmodusPickerOfferRow(:final offer) => KochmodusPickerItemRow(
        key: KochmodusItemPickerSheet.rowKey(offer.item.id),
        offer: offer,
        match: _matches.contains(offer.item.id),
        holder: widget.holders[offer.item.id],
        number: _picked.indexOf(offer.item.id) + 1,
        tiltLeft: index.isEven,
        onTap: () => _toggle(offer.item.id),
      ),
    },
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muted = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: FoodLabelColors.of(context).muted);
    final searching = _query.trim().isNotEmpty;
    final list = InventoryListPreferencesBuilder(
      builder: (context, preferences) {
        final rows = kochmodusPickerRows(
          widget.offers,
          preferences: preferences,
          query: _query,
        );
        if (rows.suggested.isEmpty && rows.all.isEmpty) {
          return SliverToBoxAdapter(
            child: searching
                ? Text(l10n.kochmodusPickerNoHits, style: muted)
                : const SizedBox.shrink(),
          );
        }
        final titled = rows.suggested.isNotEmpty;
        return SliverMainAxisGroup(
          slivers: [
            if (titled)
              SliverToBoxAdapter(
                child: KochmodusGroupTitle(
                  key: KochmodusItemPickerSheet.suggestedKey,
                  title: l10n.kochmodusPickerSuggested,
                ),
              ),
            _rows(rows.suggested),
            if (titled && rows.all.isNotEmpty)
              SliverToBoxAdapter(
                child: KochmodusGroupTitle(
                  key: KochmodusItemPickerSheet.allKey,
                  title: l10n.kochmodusPickerAll,
                ),
              ),
            _rows(rows.all),
          ],
        );
      },
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xs,
        children: [
          // The head and the list scroll; a search fills the sheet, the field
          // stays.
          Flexible(
            fit: searching ? FlexFit.tight : FlexFit.loose,
            child: CustomScrollView(
              shrinkWrap: true,
              slivers: [
                SliverToBoxAdapter(
                  child: KochmodusPickerHead(
                    title: widget.title,
                    hint: _picked.length > 1
                        ? l10n.cookPickerOrder
                        : l10n.cookPickerHint,
                    onSearch: (query) => setState(() => _query = query),
                  ),
                ),
                list,
              ],
            ),
          ),
          // Pinned under the list, above the keyboard while searching: the
          // way out when the Vorrat does not hold the food.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: KochmodusItemPickerSheet.searchOtherKey,
              onPressed: () => Navigator.of(context).pop<KochmodusPickerResult>(
                (ids: const [], short: KochmodusPickerShort.keep),
              ),
              icon: const Icon(Icons.search_rounded),
              label: Text(l10n.kochmodusPickerSearchOther),
            ),
          ),
          if (_picked.isNotEmpty)
            KochmodusPickerKeep(
              need: widget.need,
              missing: _missing,
              onAnswer: _close,
            ),
        ],
      ),
    );
  }
}
