import 'package:flutter/material.dart';

/// Defines status line.
class StatusLine extends StatelessWidget {
  /// The status line.
  const StatusLine({required this.text, required this.color, super.key});

  /// The text.
  final String text;

  /// The color.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
