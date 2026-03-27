import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

class PreparedMealCover extends StatelessWidget {
  const PreparedMealCover({
    super.key,
    required this.label,
    required this.imageBytes,
    this.size = 64,
    this.borderRadius,
  });

  final String label;
  final Uint8List? imageBytes;
  final double size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius =
        borderRadius ?? BorderRadius.circular(AppInventoryEditorial.cardRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppInventoryEditorial.primary.withValues(alpha: 0.14),
            Theme.of(context).colorScheme.surfaceContainerLow,
          ],
        ),
        borderRadius: radius,
      ),
      child: SizedBox.square(
        dimension: size,
        child: ClipRRect(
          borderRadius: radius,
          child: imageBytes == null
              ? _PreparedMealCoverFallback(label: label)
              : Image.memory(
                  imageBytes!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) {
                    return _PreparedMealCoverFallback(label: label);
                  },
                ),
        ),
      ),
    );
  }
}

class _PreparedMealCoverFallback extends StatelessWidget {
  const _PreparedMealCoverFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);

    return Center(
      child: Text(
        initial.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppInventoryEditorial.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
