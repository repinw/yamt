import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_sheet_widgets.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kitchen_utensils/presentation/widgets/'
    'kitchen_utensil_image_field.dart';
import 'package:yamt/features/kitchen_utensils/provider/'
    'kitchen_utensil_image_url_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Kitchen utensil sheet result.
class KitchenUtensilSheetResult {
  /// Creates result.
  const KitchenUtensilSheetResult({
    required this.name,
    required this.imageBytes,
    required this.imageChanged,
    required this.weightGrams,
  });

  /// Name.
  final String name;

  /// New image bytes.
  final Uint8List? imageBytes;

  /// Whether image was changed.
  final bool imageChanged;

  /// Weight in grams.
  final int weightGrams;
}

/// Shows kitchen utensil sheet.
@Dependencies([preparedMealImagePicker])
Future<KitchenUtensilSheetResult?> showKitchenUtensilSheet({
  required BuildContext context,
  KitchenUtensil? initialUtensil,
}) {
  return showModalBottomSheet<KitchenUtensilSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return KitchenUtensilSheet(initialUtensil: initialUtensil);
    },
  );
}

/// Kitchen utensil add/edit sheet.
@Dependencies([preparedMealImagePicker])
class KitchenUtensilSheet extends ConsumerStatefulWidget {
  /// Creates sheet.
  const KitchenUtensilSheet({super.key, this.initialUtensil});

  /// Initial utensil for edit.
  final KitchenUtensil? initialUtensil;

  @override
  ConsumerState<KitchenUtensilSheet> createState() =>
      _KitchenUtensilSheetState();
}

class _KitchenUtensilSheetState extends ConsumerState<KitchenUtensilSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _weightController;
  Uint8List? _imageBytes;
  bool _imageChanged = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    final initialUtensil = widget.initialUtensil;
    _nameController = TextEditingController(text: initialUtensil?.name ?? '');
    _weightController = TextEditingController(
      text: initialUtensil?.weightGrams.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final initialUtensil = widget.initialUtensil;
    final imagePath = initialUtensil?.imageStoragePath;
    final existingImageUrl = imagePath == null
        ? null
        : ref.watch(kitchenUtensilImageUrlProvider(imagePath)).asData?.value;
    final visibleImageUrl = _imageChanged ? null : existingImageUrl;
    final supportsCamera = ref
        .read(
          preparedMealImagePickerProvider,
        )
        .supportsCamera;

    return PreparedMealSheetContainer(
      formKey: _formKey,
      children: [
        Text(
          initialUtensil == null
              ? l10n.kitchenUtensilAddTitle
              : l10n.kitchenUtensilEditTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.kitchenUtensilNameLabel,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _weightController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.kitchenUtensilWeightLabel,
          ),
          validator: _validateWeight,
        ),
        const SizedBox(height: AppSpacing.lg),
        KitchenUtensilImageField(
          label: _nameController.text,
          imageBytes: _imageBytes,
          imageUrl: visibleImageUrl,
          supportsCamera: supportsCamera,
          isPickingImage: _isPickingImage,
          onPickImage: _pickImage,
          onClearImage: _clearImage,
        ),
        const SizedBox(height: AppSpacing.lg),
        PreparedMealSheetActions(
          primaryLabel: initialUtensil == null
              ? l10n.kitchenUtensilAddAction
              : l10n.inventoryReceiptReviewEditAction,
          onPrimaryPressed: _submit,
        ),
      ],
    );
  }

  String? _validateWeight(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final weight = int.tryParse(value?.trim() ?? '');
    if (weight == null || weight <= 0) {
      return l10n.kitchenUtensilInvalidWeight;
    }
    return null;
  }

  Future<void> _pickImage(KitchenUtensilImageSource source) async {
    setState(() {
      _isPickingImage = true;
    });

    final picker = ref.read(preparedMealImagePickerProvider);
    try {
      final imageBytes = await switch (source) {
        KitchenUtensilImageSource.camera => picker.pickFromCamera(),
        KitchenUtensilImageSource.file => picker.pickFromFile(),
      };
      if (!mounted || imageBytes == null) {
        return;
      }
      setState(() {
        _imageBytes = imageBytes;
        _imageChanged = true;
      });
    } on Object catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      log(
        'Failed to pick kitchen utensil image.',
        name: 'KitchenUtensilSheet',
        error: error,
        stackTrace: stackTrace,
      );
      _showSnackBar(
        AppLocalizations.of(context)!.kitchenUtensilImagePickFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  void _clearImage() {
    setState(() {
      _imageBytes = null;
      _imageChanged = true;
    });
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final formState = _formKey.currentState;
    if (formState == null) {
      _showSnackBar(l10n.kitchenUtensilSaveFailed);
      return;
    }
    if (!formState.validate()) {
      _showSnackBar(l10n.preparedMealFixFormErrorsMessage);
      return;
    }

    final hasName = _nameController.text.trim().isNotEmpty;
    final hasNewImage = _imageBytes != null;
    final keepsExistingImage =
        !_imageChanged && widget.initialUtensil?.imageStoragePath != null;
    if (!hasName && !hasNewImage && !keepsExistingImage) {
      _showSnackBar(l10n.kitchenUtensilIdentityRequired);
      return;
    }

    final weightGrams = int.tryParse(_weightController.text.trim());
    if (weightGrams == null || weightGrams <= 0) {
      _showSnackBar(l10n.kitchenUtensilInvalidWeight);
      return;
    }

    Navigator.of(context).pop(
      KitchenUtensilSheetResult(
        name: _nameController.text,
        imageBytes: _imageBytes,
        imageChanged: _imageChanged,
        weightGrams: weightGrams,
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
