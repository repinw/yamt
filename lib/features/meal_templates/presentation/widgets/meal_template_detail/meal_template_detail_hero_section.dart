// Internal detail widget is public only for sibling split files.
// ignore_for_file: public_member_api_docs

import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';

class MealTemplateHeroSection extends StatelessWidget {
  const MealTemplateHeroSection({
    required this.templateName,
    required this.imageBytes,
    required this.imageUrl,
    required this.portionsLabel,
    required this.basePortionsLabel,
    required this.onDecreasePortions,
    required this.onIncreasePortions,
    super.key,
  });

  static const _heroHeight = 252.0;

  final String templateName;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final String portionsLabel;
  final String basePortionsLabel;
  final VoidCallback? onDecreasePortions;
  final VoidCallback onIncreasePortions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _heroHeight + 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: _heroHeight,
            child: _MealTemplateHeroImage(
              templateName: templateName,
              imageBytes: imageBytes,
              imageUrl: imageUrl,
            ),
          ),
          Positioned(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            bottom: 0,
            child: _MealTemplatePortionCard(
              portionsLabel: portionsLabel,
              basePortionsLabel: basePortionsLabel,
              onDecreasePortions: onDecreasePortions,
              onIncreasePortions: onIncreasePortions,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealTemplateHeroImage extends StatelessWidget {
  const _MealTemplateHeroImage({
    required this.templateName,
    required this.imageBytes,
    required this.imageUrl,
  });

  final String templateName;
  final Uint8List? imageBytes;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalizedImageUrl = normalizeProductImageUrl(imageUrl);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageBytes != null)
          Image.memory(
            imageBytes!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) {
              return _MealTemplateHeroFallback(templateName: templateName);
            },
          )
        else if (normalizedImageUrl != null)
          AppCachedNetworkImage(
            imageUrl: normalizedImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) {
              return _MealTemplateHeroFallback(templateName: templateName);
            },
          )
        else
          _MealTemplateHeroFallback(templateName: templateName),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.34),
                Colors.black.withValues(alpha: 0.08),
                Color.alphaBlend(
                  colors.surface.withValues(alpha: 0.94),
                  colors.surface,
                ),
              ],
              stops: const [0, 0.42, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _MealTemplateHeroFallback extends StatelessWidget {
  const _MealTemplateHeroFallback({required this.templateName});

  final String templateName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initial = templateName.trim().isEmpty
        ? '?'
        : templateName.trim().substring(0, 1).toUpperCase();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryContainer, colors.surfaceContainerHighest],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MealTemplatePortionCard extends StatelessWidget {
  const _MealTemplatePortionCard({
    required this.portionsLabel,
    required this.basePortionsLabel,
    required this.onDecreasePortions,
    required this.onIncreasePortions,
  });

  final String portionsLabel;
  final String basePortionsLabel;
  final VoidCallback? onDecreasePortions;
  final VoidCallback onIncreasePortions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppEditorial.cardRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          AppEditorialSurfaces.ambientBoxShadow(
            colors,
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppEditorial.glassBlur,
            sigmaY: AppEditorial.glassBlur,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest.withValues(alpha: 0.9),
              borderRadius: radius,
              border: Border.all(
                color: AppEditorialSurfaces.ghostBorder(
                  colors,
                ).withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  _PortionAdjustButton(
                    icon: Icons.remove_rounded,
                    onPressed: onDecreasePortions,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          portionsLabel,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          basePortionsLabel,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _PortionAdjustButton(
                    icon: Icons.add_rounded,
                    onPressed: onIncreasePortions,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PortionAdjustButton extends StatelessWidget {
  const _PortionAdjustButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      style: IconButton.styleFrom(
        backgroundColor: colors.surfaceContainerLow,
        foregroundColor: colors.primary,
        disabledBackgroundColor: colors.surfaceContainerHighest,
        disabledForegroundColor: colors.onSurfaceVariant,
      ),
    );
  }
}
