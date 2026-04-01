import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

/// Shared elevated surface used by statistics overview and detail sections.
class StatisticsSurfaceCard extends StatelessWidget {
  const StatisticsSurfaceCard({
    super.key,
    required this.child,
    this.padding = AppInsets.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
