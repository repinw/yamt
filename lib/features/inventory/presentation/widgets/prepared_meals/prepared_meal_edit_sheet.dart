import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_cover.dart';
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
  const PreparedMealEditSheet({super.key, required this.meal});

  /// The meal.
  final PreparedMeal meal;

  @override
  ConsumerState<PreparedMealEditSheet> createState() =>
      _PreparedMealEditSheetState();
}

class _PreparedMealEditSheetState extends ConsumerState<PreparedMealEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  Uint8List? _imageBytes;
  var _imageChanged = false;
  var _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meal.name);
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_onNameChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final imageRef = maybeLocalImageAssetRef(widget.meal.imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;
    final previewImageBytes = _imageChanged ? _imageBytes : storedImageBytes;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxxl,
        ),
        child: DecoratedBox(
          decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
            colors,
            borderRadius: BorderRadius.circular(
              AppInventoryEditorial.cardRadius,
            ),
          ),
          child: Padding(
            padding: AppInsets.card,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.preparedMealEditTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: l10n.preparedMealNameLabel,
                        suffixIcon: IconButton(
                          tooltip: l10n.preparedMealClearNameAction,
                          onPressed: _nameController.clear,
                          icon: const Icon(Icons.cleaning_services_outlined),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.preparedMealInvalidName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.preparedMealImageLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PreparedMealCover(
                          label: _nameController.text,
                          imageBytes: previewImageBytes,
                          size: 88,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  if (_supportsCamera)
                                    FilledButton.tonalIcon(
                                      onPressed: _isPickingImage
                                          ? null
                                          : () => _pickImage(
                                              _PreparedMealImageSource.camera,
                                            ),
                                      icon: const Icon(
                                        Icons.photo_camera_outlined,
                                      ),
                                      label: Text(
                                        l10n.preparedMealImageCameraAction,
                                      ),
                                    ),
                                  FilledButton.tonalIcon(
                                    onPressed: _isPickingImage
                                        ? null
                                        : () => _pickImage(
                                            _PreparedMealImageSource.file,
                                          ),
                                    icon: const Icon(
                                      Icons.add_photo_alternate_outlined,
                                    ),
                                    label: Text(
                                      previewImageBytes == null
                                          ? l10n.preparedMealAddImageAction
                                          : l10n.preparedMealChangeImageAction,
                                    ),
                                  ),
                                  if (previewImageBytes != null)
                                    TextButton.icon(
                                      onPressed: _isPickingImage
                                          ? null
                                          : _clearImage,
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                      label: Text(
                                        l10n.preparedMealRemoveImageAction,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                l10n.preparedMealImageHint,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              l10n.inventoryReceiptReviewCancelAction,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: FilledButton(
                            onPressed: _submit,
                            child: Text(l10n.inventoryReceiptReviewSaveAction),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _supportsCamera {
    return ref.read(preparedMealImagePickerProvider).supportsCamera;
  }

  Future<void> _pickImage(_PreparedMealImageSource source) async {
    setState(() {
      _isPickingImage = true;
    });

    try {
      final picker = ref.read(preparedMealImagePickerProvider);
      final imageBytes = await switch (source) {
        _PreparedMealImageSource.camera => picker.pickFromCamera(),
        _PreparedMealImageSource.file => picker.pickFromFile(),
      };
      if (!mounted || imageBytes == null) {
        return;
      }
      setState(() {
        _imageBytes = imageBytes;
        _imageChanged = true;
      });
    } on PreparedMealImagePickerException catch (error) {
      if (!mounted) {
        return;
      }
      _showImageError(error.code);
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

  void _showImageError(String errorCode) {
    final l10n = AppLocalizations.of(context)!;
    final message = switch (errorCode) {
      PreparedMealImagePickerErrorCodes.imageTooLarge =>
        l10n.preparedMealImageTooLarge,
      _ => l10n.preparedMealImagePickFailed,
    };

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _onNameChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }
}

enum _PreparedMealImageSource { camera, file }
