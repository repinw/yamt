import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/inventory_eat_flow_hero_image.dart';

/// Shared hero for inventory eat flows.
class InventoryEatFlowHero extends StatelessWidget {
  /// Creates shared eat flow hero.
  const InventoryEatFlowHero({
    required this.title,
    required this.eyebrow,
    required this.cancelButtonKey,
    required this.fallback,
    super.key,
    this.imageUrl,
    this.imageBytes,
    this.imageKey,
  });

  static const _thumbSize = 64.0;

  /// Title.
  final String title;

  /// Eyebrow text.
  final String eyebrow;

  /// Optional image URL.
  final String? imageUrl;

  /// Optional local image bytes.
  final Uint8List? imageBytes;

  /// Image/fallback key.
  final Key? imageKey;

  /// Cancel button key.
  final Key cancelButtonKey;

  /// Fallback widget.
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: SizedBox.square(
              key: imageKey,
              dimension: _thumbSize,
              child: InventoryEatFlowHeroImage(
                imageUrl: imageUrl,
                imageBytes: imageBytes,
                fallback: fallback,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: colors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        eyebrow.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          IconButton.filledTonal(
            key: cancelButtonKey,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}
