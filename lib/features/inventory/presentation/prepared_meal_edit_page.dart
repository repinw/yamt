import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/domain/eat_meal_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_combine_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_amount_unit_l10n.dart';
import 'package:yamt/features/inventory/presentation/inventory_combine_pick_page.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_list_entry.dart';
import 'package:yamt/features/inventory/presentation/models/prepared_meal_edit_draft.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_combine_food_row.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_framed_box.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_meal_portions_row.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_meal_table.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_scaffold.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_text_link.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/prepared_meal_edit_header.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/prepared_meal_image_picker_field.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the editor of [meal]. Returns what to save, or null when the user
/// closes it.
Future<PreparedMealEditResult?> showPreparedMealEditPage(
  BuildContext context, {
  required PreparedMeal meal,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<PreparedMealEditResult>(
      fullscreenDialog: true,
      builder: (_) => PreparedMealEditPage(meal: meal),
    ),
  );
}

/// Meal editor, drawn like the eat page: picture and name, the ingredients
/// with a ruler each, more foods from the stock, the portions and the
/// nutrition table of the edited meal.
///
/// Once portions are eaten, only the name and the picture can change.
class PreparedMealEditPage extends ConsumerStatefulWidget {
  /// Creates the editor.
  const new({required this.meal, super.key});

  /// Key of the save button.
  static const saveKey = Key('prepared_meal_edit_save');

  /// Key of the link that adds foods from the stock.
  static const addKey = Key('prepared_meal_edit_add');

  /// The meal.
  final PreparedMeal meal;

  @override
  ConsumerState<PreparedMealEditPage> createState() =>
      _PreparedMealEditPageState();
}

class _PreparedMealEditPageState extends ConsumerState<PreparedMealEditPage>
    with PreparedMealImagePickerStateMixin<PreparedMealEditPage> {
  late final _name = TextEditingController(text: widget.meal.name);
  late int _portions = widget.meal.totalPortions;
  late List<PreparedMealEditRow> _rows;
  String? _openId;
  var _imageChanged = false;
  Uint8List? _imageBytes;

  PreparedMeal get _meal => widget.meal;

  bool get _isLocked => _meal.remainingPortions < _meal.totalPortions;

  @override
  void initState() {
    super.initState();
    final items = ref.read(inventoryItemsControllerProvider).value ?? [];
    _rows = [
      for (final component in _meal.components)
        PreparedMealEditRow.ofComponent(
          component,
          available: _available(items, component.inventoryItemId),
        ),
    ];
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final imageRef = maybeLocalImageAssetRef(_meal.imageAssetId);
    final storedBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).value;
    final imageBytes = _imageChanged ? _imageBytes : storedBytes;
    final nutrition = EatMealNutrition.combine([
      for (final row in _rows) row.food,
    ]);
    final canSave =
        _name.text.trim().isNotEmpty &&
        (_rows.isNotEmpty || _meal.components.isEmpty);

    return EatPageScaffold(
      whenControl: const SizedBox.shrink(),
      kcal: nutrition.total.kcal,
      confirmButtonKey: PreparedMealEditPage.saveKey,
      confirmLabel: l10n.productEditorSaveAction,
      onConfirm: canSave ? _save : null,
      confirmHint: _rows.isEmpty && _meal.components.isNotEmpty
          ? l10n.preparedMealEmptyIngredientsMessage
          : null,
      cancelButtonKey: const Key('prepared_meal_edit_close'),
      children: [
        PreparedMealEditHeader(
          nameController: _name,
          imageUrl: _imageChanged ? null : _meal.imageUrl,
          imageBytes: imageBytes,
          collageImageUrls: [for (final row in _rows) row.imageUrl],
          fallbackLetter: inventoryPictureLetter(_name.text),
          hasPicture:
              imageBytes != null || (!_imageChanged && _meal.imageUrl != null),
          supportsCamera: supportsPreparedMealCamera,
          onPickImage: _pickImage,
          onClearImage: () => setState(() {
            _imageBytes = null;
            _imageChanged = true;
          }),
        ),
        if (_isLocked)
          Text(
            l10n.preparedMealEditLockedHint,
            key: const Key('prepared_meal_edit_locked_hint'),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.muted),
          ),
        EatFramedBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final row in _rows) _rowOf(row, l10n),
              if (!_isLocked)
                EatTextLink(
                  buttonKey: PreparedMealEditPage.addKey,
                  label: l10n.eatPageCombineAdd,
                  onPressed: _add,
                ),
            ],
          ),
        ),
        if (!_isLocked)
          EatMealPortionsRow(
            portions: _portions,
            onChanged: (portions) => setState(() => _portions = portions),
          ),
        EatMealTable(meal: nutrition, portions: _portions),
      ],
    );
  }

  Widget _rowOf(PreparedMealEditRow row, AppLocalizations l10n) {
    final canEdit = !_isLocked && row.hasRuler;
    return EatCombineFoodRow(
      key: ValueKey<String>(row.itemId),
      name: row.name,
      amount: l10n.inventoryEatSheetAmountWithUnit(
        '${row.amount}',
        row.unit.localizedName(l10n),
      ),
      kcal: switch (row.eaten.kcal) {
        final kcal? => l10n.eatPageKcal(kcal.round()),
        null => null,
      },
      isOpen: _openId == row.itemId,
      onTap: () =>
          setState(() => _openId = _openId == row.itemId ? null : row.itemId),
      onRemove: _isLocked
          ? null
          : () => setState(
              () => _rows = [
                for (final other in _rows)
                  if (other.itemId != row.itemId) other,
              ],
            ),
      ruler: canEdit
          ? EatRuler(
              value: row.amount.toDouble(),
              max: row.maxAmount.toDouble(),
              step: AppFoodLabel.mealRulerStep,
              marks: const <EatRulerMark>[],
              onChanged: (value) => _setAmount(row.itemId, value.round()),
            )
          : null,
    );
  }

  void _setAmount(String itemId, int amount) {
    setState(() {
      _rows = [
        for (final row in _rows)
          if (row.itemId == itemId) row.withAmount(amount) else row,
      ];
    });
  }

  /// Picks more foods from the stock; each joins with its default amount.
  Future<void> _add() async {
    final items = ref.read(inventoryItemsControllerProvider).value ?? [];
    final picked = await showInventoryCombinePickPage(
      context,
      candidates: inventoryMealCandidates(
        items,
        taken: {for (final row in _rows) row.itemId},
      ),
      canSearch: false,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _rows = [
        ..._rows,
        for (final item in picked.stock)
          if (defaultMealFoodAmount(item) case final amount?)
            ?PreparedMealEditRow.ofItem(item, amount),
      ];
    });
  }

  Future<void> _pickImage(PreparedMealImageSource source) {
    return pickPreparedMealImage(
      source: source,
      onPicked: (bytes) {
        _imageBytes = bytes;
        _imageChanged = true;
      },
    );
  }

  void _save() {
    Navigator.of(context).pop(
      PreparedMealEditResult(
        name: _name.text.trim(),
        imageChanged: _imageChanged,
        imageBytes: _imageBytes,
        totalPortions: _portions,
        items: [for (final row in _rows) row.input],
      ),
    );
  }

  static int _available(List<InventoryItem> items, String itemId) {
    final item = items.firstWhereOrNull((item) => item.id == itemId);
    return item == null ? 0 : consumableInventoryAmount(item) ?? 0;
  }
}
