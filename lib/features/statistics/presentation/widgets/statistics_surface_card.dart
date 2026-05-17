import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';

/// Shared elevated surface used by statistics overview and detail sections.
class StatisticsSurfaceCard extends StatelessWidget {
  /// The statistics surface card.
  const StatisticsSurfaceCard({
    required this.child,
    super.key,
    this.padding = AppInsets.card,
  });

  /// The child.
  final Widget child;

  /// The padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: AppEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
