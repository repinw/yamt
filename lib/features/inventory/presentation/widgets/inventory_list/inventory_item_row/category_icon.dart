import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.name});

  static const _size = 50.0;
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final emoji = _resolveEmoji(name);
    final backgroundColor = _resolveBackgroundColor(
      name,
      colors.secondaryContainer.withValues(alpha: 0.75),
    );
    final borderColor = colors.outlineVariant.withValues(alpha: 0.35);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: backgroundColor,
        border: Border.all(color: borderColor),
      ),
      child: SizedBox.square(
        dimension: _size,
        child: Center(
          child: Text(emoji, style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
    );
  }
}
