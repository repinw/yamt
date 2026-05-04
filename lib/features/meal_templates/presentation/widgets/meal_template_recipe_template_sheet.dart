import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_url_parser.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines prepared meal recipe template draft.
class PreparedMealRecipeTemplateDraft {
  /// The prepared meal recipe template draft.
  const PreparedMealRecipeTemplateDraft({
    required this.recipeUrl,
    required this.name,
    required this.totalPortions,
  });

  /// The recipe url.
  final String recipeUrl;

  /// The name.
  final String name;

  /// The total portions.
  final int? totalPortions;
}

/// Show prepared meal recipe template sheet.
Future<PreparedMealRecipeTemplateDraft?> showPreparedMealRecipeTemplateSheet(
  BuildContext context, {
  PreparedMealRecipeTemplateDraft? initialDraft,
  String? title,
  String? submitLabel,
}) {
  return showModalBottomSheet<PreparedMealRecipeTemplateDraft>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _PreparedMealRecipeTemplateSheet(
      initialDraft: initialDraft,
      title: title,
      submitLabel: submitLabel,
    ),
  );
}

class _PreparedMealRecipeTemplateSheet extends StatefulWidget {
  const _PreparedMealRecipeTemplateSheet({
    this.initialDraft,
    this.title,
    this.submitLabel,
  });

  final PreparedMealRecipeTemplateDraft? initialDraft;
  final String? title;
  final String? submitLabel;

  @override
  State<_PreparedMealRecipeTemplateSheet> createState() =>
      _PreparedMealRecipeTemplateSheetState();
}

class _PreparedMealRecipeTemplateSheetState
    extends State<_PreparedMealRecipeTemplateSheet> {
  late final TextEditingController _recipeUrlController = TextEditingController(
    text: widget.initialDraft?.recipeUrl ?? '',
  );
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initialDraft?.name ?? '',
  );
  late final TextEditingController _portionsController = TextEditingController(
    text: widget.initialDraft?.totalPortions?.toString() ?? '',
  );

  String? _recipeUrlErrorText;
  String? _portionsErrorText;

  @override
  void dispose() {
    _recipeUrlController.dispose();
    _nameController.dispose();
    _portionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          bottomInset + AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title ?? l10n.preparedMealTemplateRecipeSheetTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.preparedMealTemplateRecipeSheetSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _recipeUrlController,
                keyboardType: TextInputType.url,
                onChanged: _onRecipeUrlChanged,
                decoration: InputDecoration(
                  labelText: l10n.preparedMealTemplateRecipeUrlLabel,
                  hintText: l10n.preparedMealTemplateRecipeUrlHint,
                  errorText: _recipeUrlErrorText,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.preparedMealTemplateNameLabel,
                  helperText: l10n.preparedMealTemplateNameHelper,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _portionsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.preparedMealTemplatePortionsLabel,
                  helperText: l10n.preparedMealTemplatePortionsHelper,
                  errorText: _portionsErrorText,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.inventoryReceiptReviewCancelAction),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _submit(context),
                      icon: const Icon(Icons.add_link_rounded),
                      label: Text(
                        widget.submitLabel ??
                            l10n.preparedMealTemplateCreateFromRecipeAction,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final normalizedRecipeUrl = normalizePreparedMealRecipeUrl(
      _recipeUrlController.text,
    );
    final rawPortions = _portionsController.text.trim();
    final portions = rawPortions.isEmpty ? null : int.tryParse(rawPortions);

    setState(() {
      _recipeUrlErrorText = normalizedRecipeUrl == null
          ? l10n.preparedMealTemplateRecipeUrlInvalid
          : null;
      _portionsErrorText =
          rawPortions.isNotEmpty && (portions == null || portions < 1)
          ? l10n.preparedMealInvalidPortionsRange
          : null;
    });
    if (_recipeUrlErrorText != null || _portionsErrorText != null) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(
      PreparedMealRecipeTemplateDraft(
        recipeUrl: normalizedRecipeUrl!,
        name: _nameController.text.trim(),
        totalPortions: portions,
      ),
    );
  }

  void _onRecipeUrlChanged(String value) {
    final normalizedRecipeUrl = normalizePreparedMealRecipeUrl(value);
    final shouldAutoclean = value.contains(RegExp(r'\s'));

    if (shouldAutoclean &&
        normalizedRecipeUrl != null &&
        normalizedRecipeUrl != value.trim()) {
      _recipeUrlController.value = TextEditingValue(
        text: normalizedRecipeUrl,
        selection: TextSelection.collapsed(offset: normalizedRecipeUrl.length),
      );
    }

    if (_recipeUrlErrorText != null) {
      setState(() {
        _recipeUrlErrorText = null;
      });
    }
  }
}
