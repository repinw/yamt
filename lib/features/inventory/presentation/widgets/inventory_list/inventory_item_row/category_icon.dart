import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/product_image_url.dart';
import 'package:yamt/features/inventory/provider/'
    'inventory_barcode_image_provider.dart';

class CategoryIcon extends ConsumerWidget {
  const CategoryIcon({
    super.key,
    required this.name,
    required this.barcode,
    this.imageUrl,
  });

  static const _size = AppInventoryEditorial.categoryTileSize;
  static const _imageInset = 4.0;
  static const _fallbackEmoji = '🍽️';

  static const Map<String, String> _emojiByCategory = {
    'banana': '🍌',
    'basilikum': '🌿',
    'bier': '🍺',
    'brot': '🍞',
    'broetchen': '🥐',
    'champignon': '🍄',
    'chips': '🍟',
    'dip': '🥣',
    'eier': '🥚',
    'energydrink': '🥤',
    'fertiggericht': '🍱',
    'fruchtgummi': '🍬',
    'hackfleisch': '🥩',
    'haehnchen': '🍗',
    'haehnchenleber': '🍗',
    'bacon': '🥓',
    'fischstaebchen': '🐟',
    'milch': '🥛',
    'mozzarella': '🧀',
    'muesliriegel': '🍫',
    'musliriegel': '🍫',
    'nudelsalat': '🥗',
    'pfeffer': '🌶️',
    'pommes': '🍟',
    'quark': '🥣',
    'sahne': '🥛',
    'salami': '🥓',
    'salat': '🥬',
    'sauresahne': '🥣',
    'schinken': '🍖',
    'schmelzkaese': '🧀',
    'schokolade': '🍫',
    'sonnenblumenkerne': '🌻',
    'streichfett': '🧈',
    'tomate': '🍅',
    'wasser': '💧',
    'wurst': '🌭',
    'zucchini': '🥒',
  };

  static const Map<String, Color> _backgroundByCategory = {
    'banana': Color(0xFFF7F3DE),
    'bier': Color(0xFFF8EEDB),
    'brot': Color(0xFFF8EEE4),
    'broetchen': Color(0xFFF8EEE4),
    'eier': Color(0xFFF8EEE4),
    'hackfleisch': Color(0xFFF9E8E8),
    'milch': Color(0xFFE8EEF7),
    'mozzarella': Color(0xFFF6F2E7),
    'nudelsalat': Color(0xFFEAF4E8),
    'pommes': Color(0xFFF8EEE4),
    'salat': Color(0xFFEAF4E8),
    'schokolade': Color(0xFFF4ECE7),
    'tomate': Color(0xFFF9ECEB),
    'wasser': Color(0xFFEAF0F8),
    'wurst': Color(0xFFF9ECEB),
    'zucchini': Color(0xFFEAF4E8),
  };

  final String name;
  final String? barcode;
  final String? imageUrl;

  String _normalize(String value) {
    final lower = value.trim().toLowerCase();
    final normalized = lower
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(RegExp(r'\s+'), '');
    return normalized;
  }

  String _resolveEmoji(String rawName) {
    final key = _normalize(rawName);
    if (key.isEmpty) {
      return _fallbackEmoji;
    }
    return _emojiByCategory[key] ?? _fallbackEmoji;
  }

  Color _resolveBackgroundColor(String rawName, Color fallbackColor) {
    final key = _normalize(rawName);
    if (key.isEmpty) {
      return fallbackColor;
    }
    return _backgroundByCategory[key] ?? fallbackColor;
  }

  String? _resolveImageUrl(WidgetRef ref) {
    final directImageUrl = normalizeProductImageUrl(imageUrl);
    if (directImageUrl != null && directImageUrl.isNotEmpty) {
      return directImageUrl;
    }

    final normalizedBarcode = barcode?.trim();
    if (normalizedBarcode == null || normalizedBarcode.isEmpty) {
      return null;
    }
    final resolvedByBarcode = ref.watch(
      inventoryBarcodeImageUrlProvider(
        normalizedBarcode,
      ).select((imageAsync) => imageAsync.asData?.value),
    );
    return normalizeProductImageUrl(resolvedByBarcode);
  }

  int _resolveImageCacheDimension(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final imageSize = (_size - (_imageInset * 2)) * devicePixelRatio;
    return imageSize.ceil();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final emojiTextStyle = Theme.of(context).textTheme.titleLarge;
    final emoji = _resolveEmoji(name);
    final imageUrl = _resolveImageUrl(ref);
    final imageCacheDimension = _resolveImageCacheDimension(context);
    final backgroundColor = _resolveBackgroundColor(
      name,
      colors.secondaryContainer.withValues(alpha: 0.75),
    );
    final borderRadius = BorderRadius.circular(AppRadius.xl);

    return ClipRRect(
      borderRadius: borderRadius,
      clipBehavior: Clip.hardEdge,
      child: DecoratedBox(
        decoration: BoxDecoration(color: backgroundColor),
        child: SizedBox.square(
          dimension: _size,
          child: Center(
            child: imageUrl == null
                ? Text(emoji, style: emojiTextStyle)
                : Image.network(
                    imageUrl,
                    width: _size,
                    height: _size,
                    fit: BoxFit.cover,
                    cacheWidth: imageCacheDimension,
                    cacheHeight: imageCacheDimension,
                    filterQuality: FilterQuality.low,
                    gaplessPlayback: true,
                    errorBuilder: (_, error, stackTrace) {
                      return Text(emoji, style: emojiTextStyle);
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
