import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_url_parser.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _preparedMealRecipeTemplateSheetLogName =
    'PreparedMealRecipeTemplateSheet';

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
  bool useRootNavigator = true,
}) {
  return showModalBottomSheet<PreparedMealRecipeTemplateDraft>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
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
  bool _advancedExpanded = false;

  @override
  void initState() {
    super.initState();
    _advancedExpanded =
        widget.initialDraft != null ||
        _nameController.text.isNotEmpty ||
        _portionsController.text.isNotEmpty;
  }

  @override
  void dispose() {
    _recipeUrlController.dispose();
    _nameController.dispose();
    _portionsController.dispose();
    super.dispose();
  }

  Future<void> _handleClipboardPaste() async {
    unawaited(HapticFeedback.lightImpact());
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text != null && text.trim().isNotEmpty) {
        final normalized = normalizePreparedMealRecipeUrl(text.trim());
        if (normalized != null) {
          _recipeUrlController.text = normalized;
          _onRecipeUrlChanged(normalized);
          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            var host = normalized;
            try {
              final uri = Uri.parse(normalized);
              host = uri.host.replaceFirst('www.', '');
            } on Object catch (error, stackTrace) {
              log(
                'Failed to extract host from normalized recipe URL.',
                name: _preparedMealRecipeTemplateSheetLogName,
                error: error,
                stackTrace: stackTrace,
              );
            }

            setState(() {
              _recipeUrlErrorText = null;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.preparedMealTemplateClipboardPasteSuccess(host),
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        }
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _recipeUrlErrorText = l10n.preparedMealTemplateClipboardNoLinkFound;
        });
      }
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read recipe URL from clipboard.',
        name: _preparedMealRecipeTemplateSheetLogName,
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _recipeUrlErrorText = l10n.preparedMealTemplateClipboardNoLinkFound;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          bottomInset + AppSpacing.xxl,
        ),
        child: DecoratedBox(
          decoration: AppEditorialSurfaces.liftedCardDecoration(
            colors,
            borderRadius: BorderRadius.circular(AppEditorial.cardRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SheetHandleIndicator(colors: colors),
                  _SheetHeader(
                    title:
                        widget.title ??
                        l10n.preparedMealTemplateRecipeSheetTitle,
                    subtitle: l10n.preparedMealTemplateRecipeSheetSubtitle,
                    onClose: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _WelcomeHeaderCard(
                    message: l10n.preparedMealTemplateRecipeGreetingSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _recipeUrlController,
                    keyboardType: TextInputType.url,
                    onChanged: _onRecipeUrlChanged,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: l10n.preparedMealTemplateRecipeUrlLabel,
                      hintText: l10n.preparedMealTemplateRecipeUrlHint,
                      errorText: _recipeUrlErrorText,
                      prefixIcon: ShaderMask(
                        shaderCallback: (bounds) =>
                            AppEditorialSurfaces.soulGradient(
                              colors,
                            ).createShader(bounds),
                        child: const Icon(
                          Icons.link_rounded,
                          color: Colors.white,
                        ),
                      ),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _recipeUrlController,
                        builder: (context, value, _) {
                          if (value.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _recipeUrlController.clear();
                              _onRecipeUrlChanged('');
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _recipeUrlController,
                    builder: (context, value, _) {
                      if (value.text.isNotEmpty) {
                        return const SizedBox.shrink();
                      }
                      return _ClipboardPasteCard(
                        onTap: _handleClipboardPaste,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _AdvancedOptionsPanel(
                    isExpanded: _advancedExpanded,
                    nameController: _nameController,
                    portionsController: _portionsController,
                    portionsErrorText: _portionsErrorText,
                    onToggle: () {
                      setState(() {
                        _advancedExpanded = !_advancedExpanded;
                      });
                      unawaited(HapticFeedback.selectionClick());
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ActionButtonsRow(
                    submitLabel: widget.submitLabel,
                    onCancel: () {
                      unawaited(HapticFeedback.lightImpact());
                      Navigator.of(context).pop();
                    },
                    onSubmit: () {
                      unawaited(HapticFeedback.mediumImpact());
                      _submit(context);
                    },
                  ),
                ],
              ),
            ),
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

/// A subtle handle bar at the top of the modal bottom sheet.
class _SheetHandleIndicator extends StatelessWidget {
  const _SheetHandleIndicator({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.onSurfaceVariant.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}

/// Standardized top title bar for the sheet.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: onClose,
          style: IconButton.styleFrom(
            backgroundColor: colors.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            foregroundColor: colors.onSurfaceVariant,
            padding: const EdgeInsets.all(AppSpacing.xs),
          ),
        ),
      ],
    );
  }
}

/// A compact, warm welcome card replacing bulky banners.
class _WelcomeHeaderCard extends StatelessWidget {
  const _WelcomeHeaderCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          const Text(
            '🍳',
            style: TextStyle(fontSize: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A beautiful magic card prompting the user to paste their clipboard.
class _ClipboardPasteCard extends StatelessWidget {
  const _ClipboardPasteCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.12),
            colors.secondary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: AppInkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.assignment_turned_in_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.preparedMealTemplateClipboardTitle,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        l10n.preparedMealTemplateClipboardPasteHelper,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: colors.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An elegant expandable panel for advanced template configuration.
class _AdvancedOptionsPanel extends StatelessWidget {
  const _AdvancedOptionsPanel({
    required this.isExpanded,
    required this.nameController,
    required this.portionsController,
    required this.portionsErrorText,
    required this.onToggle,
  });

  final bool isExpanded;
  final TextEditingController nameController;
  final TextEditingController portionsController;
  final String? portionsErrorText;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: isExpanded ? colors.primary : colors.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.preparedMealTemplateAdvancedOptionsTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isExpanded
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: !isExpanded
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: l10n.preparedMealTemplateNameLabel,
                          helperText: l10n.preparedMealTemplateNameHelper,
                          prefixIcon: const Icon(
                            Icons.drive_file_rename_outline_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: portionsController,
                        keyboardType: TextInputType.number,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: l10n.preparedMealTemplatePortionsLabel,
                          helperText: l10n.preparedMealTemplatePortionsHelper,
                          errorText: portionsErrorText,
                          prefixIcon: const Icon(Icons.restaurant_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// Action buttons for confirming or canceling template creation.
class _ActionButtonsRow extends StatelessWidget {
  const _ActionButtonsRow({
    required this.onCancel,
    required this.onSubmit,
    this.submitLabel,
  });

  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final String? submitLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: Text(l10n.inventoryReceiptReviewCancelAction),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: AppEditorialSurfaces.soulGradient(colors),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: FilledButton.icon(
              onPressed: onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(
                submitLabel ?? l10n.preparedMealTemplateCreateFromRecipeAction,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
