// Internal split widgets are public only so sibling files can import them.
// ignore_for_file: public_member_api_docs, use_key_in_widget_constructors

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';

class CookingFlowIntroMealHero extends StatelessWidget {
  const CookingFlowIntroMealHero({
    required this.label,
    required this.imageBytes,
    required this.imageUrl,
  });

  final String label;
  final Uint8List? imageBytes;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppInventoryEditorial.cardRadius);
    final normalizedImageUrl = normalizeProductImageUrl(imageUrl);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: <BoxShadow>[
          AppInventoryEditorialSurfaces.ambientBoxShadow(
            colors,
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      colors.primary.withValues(alpha: 0.14),
                      colors.surfaceContainerLow,
                    ],
                  ),
                ),
                child: imageBytes != null
                    ? Image.memory(
                        imageBytes!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) {
                          return _IntroMealHeroFallback(label: label);
                        },
                      )
                    : normalizedImageUrl != null
                    ? AppCachedNetworkImage(
                        imageUrl: normalizedImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) {
                          return _IntroMealHeroFallback(label: label);
                        },
                      )
                    : _IntroMealHeroFallback(label: label),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.08),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroMealHeroFallback extends StatelessWidget {
  const _IntroMealHeroFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);

    return Center(
      child: Text(
        initial.toUpperCase(),
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
