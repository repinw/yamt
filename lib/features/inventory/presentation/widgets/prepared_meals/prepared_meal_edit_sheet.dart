import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_image_picker_field.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_sheet_widgets.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines prepared meal edit sheet result.
class PreparedMealEditSheetResult {
  /// The prepared meal edit sheet result.
  const PreparedMealEditSheetResult({
    required this.name,
    required this.imageChanged,
    required this.imageBytes,
  });

  /// The name.
  final String name;

  /// The image changed.
  final bool imageChanged;

  /// The image bytes.
  final Uint8List? imageBytes;
}

/// Show prepared meal edit sheet.
Future<PreparedMealEditSheetResult?> showPreparedMealEditSheet({
  required BuildContext context,
  required PreparedMeal meal,
}) {
  return showModalBottomSheet<PreparedMealEditSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PreparedMealEditSheet(meal: meal),
  );
}

/// Defines prepared meal edit sheet.
class PreparedMealEditSheet extends ConsumerStatefulWidget {
  /// The prepared meal edit sheet.
  const PreparedMealEditSheet({required this.meal, super.key});

  /// The meal.
  final PreparedMeal meal;

  @override
  ConsumerState<PreparedMealEditSheet> createState() =>
      _PreparedMealEditSheetState();
}

class _PreparedMealEditSheetState extends ConsumerState<PreparedMealEditSheet>
    with PreparedMealImagePickerStateMixin<PreparedMealEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  Uint8List? _imageBytes;
  var _imageChanged = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meal.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final imageRef = maybeLocalImageAssetRef(widget.meal.imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;
    final previewImageBytes = _imageChanged ? _imageBytes : storedImageBytes;

    return PreparedMealSheetContainer(
      formKey: _formKey,
      children: [
        Text(
          l10n.preparedMealEditTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.md),
        PreparedMealNameField(
          controller: _nameController,
          textInputAction: TextInputAction.done,
          onChanged: _onNameChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        PreparedMealImagePickerField(
          label: _nameController.text,
          imageBytes: previewImageBytes,
          supportsCamera: supportsPreparedMealCamera,
          isPickingImage: isPickingPreparedMealImage,
          onPickImage: _pickImage,
          onClearImage: _clearImage,
        ),
        const SizedBox(height: AppSpacing.lg),
        PreparedMealSheetActions(
          primaryLabel: l10n.inventoryReceiptReviewSaveAction,
          onPrimaryPressed: _submit,
        ),
      ],
    );
  }

  Future<void> _pickImage(PreparedMealImageSource source) {
    return pickPreparedMealImage(
      source: source,
      onPicked: (imageBytes) {
        _imageBytes = imageBytes;
        _imageChanged = true;
      },
    );
  }

  void _clearImage() {
    setState(() {
      _imageBytes = null;
      _imageChanged = true;
    });
  }

  void _submit() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    Navigator.of(context).pop(
      PreparedMealEditSheetResult(
        name: _nameController.text.trim(),
        imageChanged: _imageChanged,
        imageBytes: _imageBytes == null
            ? null
            : Uint8List.fromList(_imageBytes!),
      ),
    );
  }

  void _onNameChanged(String _) {
    if (!mounted) {
      return;
    }
    setState(() {});
  }
}
