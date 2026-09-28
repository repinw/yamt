import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/cooking_flow/application/cooking_flow_intro_inventory_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the ingredient editor; returns the edited row, or null on cancel.
Future<CookingFlowInventoryCheckRowData?> showCookingFlowIngredientEditSheet({
  required BuildContext context,
  required CookingFlowInventoryCheckRowData row,
}) {
  return showModalBottomSheet<CookingFlowInventoryCheckRowData>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (sheetContext) {
      return _IngredientEditBottomSheet(row: row);
    },
  );
}

class _IngredientEditBottomSheet extends StatefulWidget {
  const new({required this.row});

  final CookingFlowInventoryCheckRowData row;

  @override
  State<_IngredientEditBottomSheet> createState() =>
      _IngredientEditBottomSheetState();
}

class _IngredientEditBottomSheetState
    extends State<_IngredientEditBottomSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _unitController;

  @override
  void initState() {
    super.initState();
    final amountParts = cookingFlowSplitIngredientAmountLabel(
      widget.row.amountLabel,
    );
    _nameController = TextEditingController(text: widget.row.name);
    _amountController = TextEditingController(text: amountParts.amount);
    _unitController = TextEditingController(text: amountParts.unit);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                l10n.cookflowEditIngredientTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.cookflowEditIngredientNameLabel,
                ),
                validator: _requiredFieldValidator,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.cookflowEditIngredientAmountLabel,
                      ),
                      validator: _requiredFieldValidator,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: l10n.cookflowEditIngredientUnitLabel,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cookflowCancelButton),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: _save,
                    child: Text(l10n.cookflowEditIngredientSaveAction),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredFieldValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.cookflowEditIngredientRequiredField;
    }
    return null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final name = _nameController.text.trim();
    final amount = _amountController.text.trim();
    final unit = _unitController.text.trim();
    Navigator.of(context).pop(
      widget.row.copyWith(
        name: name,
        amountLabel: unit.isEmpty ? amount : '$amount $unit',
        isEdited: true,
      ),
    );
  }
}
