import 'package:flutter/material.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_scale_label.dart';

/// Start and end labels for the Burn Week balance scale.
class DiaryBalanceScaleRow extends StatelessWidget {
  /// Creates a balance scale label row.
  const DiaryBalanceScaleRow({
    required this.startLabel,
    required this.endLabel,
    super.key,
  });

  /// Start-of-scale label.
  final String startLabel;

  /// End-of-scale label.
  final String endLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DiaryBalanceScaleLabel(startLabel),
        DiaryBalanceScaleLabel(endLabel),
      ],
    );
  }
}
