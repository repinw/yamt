import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

const _productSearchHubScrollHandleWidth = 44.0;
const _productSearchHubScrollHandleHeight = 5.0;
const _productSearchHubScrollHandleOpacity = 0.68;

/// Centered scroll affordance for the product search hub list area.
class ProductSearchHubScrollHintHandle extends StatelessWidget {
  /// Creates a product search hub scroll hint handle.
  const ProductSearchHubScrollHintHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.onSurfaceVariant.withValues(
            alpha: _productSearchHubScrollHandleOpacity,
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: const SizedBox(
          width: _productSearchHubScrollHandleWidth,
          height: _productSearchHubScrollHandleHeight,
        ),
      ),
    );
  }
}
