import SwiftUI

// Sizes mirror the Android widget (android/.../homewidget/BalanceCard.kt),
// which mirrors the Diary card: AppSpacing/AppRadius tokens in
// lib/core/constants/app_layout_constants.dart and the column widths in
// diary_nutrition_macro_row.dart / diary_quiet_kcal_row.dart.
private let quietValueWidth: CGFloat = 60  // diaryQuietMacroValueWidth
private let totalsValueWidth: CGFloat = 42  // _valueWidth (rows with totals)
private let totalsWidth: CGFloat = 68  // _totalWidth
private let valueLabelGap: CGFloat = 6  // diaryMacroValueLabelGap
private let labelWidth: CGFloat = 44  // diaryMacroLabelWidth
private let barGap: CGFloat = 10  // AppSpacing.sm
private let macroRowGap: CGFloat = 8  // diaryMacroRowGap (AppSpacing.xs)
private let segmentCount = 4

/// DiaryDailyBalanceCard in quiet mode; verbose adds the macro totals column.
struct BalanceCardContent: View {
  let snapshot: HomeDiarySnapshot

  var body: some View {
    let leftKcal = Int((snapshot.targetKcal - snapshot.eatenKcal).rounded())
    let isOverTarget = leftKcal < 0
    let accent = isOverTarget ? HomeWidgetColors.error : HomeWidgetColors.primary
    let label = isOverTarget ? localized("home_widget_over_goal") : localized("home_widget_left_today")

    VStack(alignment: .leading, spacing: 0) {
      Text(label.uppercased())
        .font(.system(size: 11, weight: .bold))
        .foregroundColor(accent)
        .lineLimit(1)
      Spacer().frame(height: 2)
      BalanceRow(
        value: formatInteger(abs(leftKcal)),
        valueColor: accent,
        valueSize: 32,
        valueWidth: quietValueWidth,
        label: localized("home_widget_unit_kcal"),
        totals: nil
      ) {
        ProgressPill(progress: ratio(snapshot.eatenKcal, snapshot.targetKcal), color: HomeWidgetColors.primary, height: 10)
      }
      Spacer().frame(height: 12)
      VStack(spacing: macroRowGap) {
        MacroRow(labelKey: "home_widget_protein", macro: snapshot.protein, color: HomeWidgetColors.protein, showTotal: snapshot.verbose)
        MacroRow(labelKey: "home_widget_carbs", macro: snapshot.carbs, color: HomeWidgetColors.carbs, showTotal: snapshot.verbose)
        MacroRow(labelKey: "home_widget_fat", macro: snapshot.fat, color: HomeWidgetColors.fat, showTotal: snapshot.verbose)
      }
    }
  }
}

/// DiaryNutritionMacroRow: remaining (or +overage) grams, label, 4-segment bar.
private struct MacroRow: View {
  let labelKey: String
  let macro: HomeDiarySnapshot.Macro
  let color: Color
  let showTotal: Bool

  var body: some View {
    let unit = localized("home_widget_unit_gram")
    let remaining = macro.target - macro.eaten
    let rounded = Int(remaining.rounded())
    let value = remaining < -0.5 ? "+\(formatInteger(-rounded))\(unit)" : "\(formatInteger(max(0, rounded)))\(unit)"

    BalanceRow(
      value: value,
      valueColor: color,
      valueSize: showTotal ? 16 : 22,
      valueWidth: showTotal ? totalsValueWidth : quietValueWidth,
      label: localized(labelKey),
      totals: showTotal
        ? (formatInteger(Int(macro.eaten.rounded())), " / \(formatInteger(Int(macro.target.rounded())))\(unit)")
        : nil
    ) {
      SegmentedBar(progress: ratio(macro.eaten, macro.target), color: color)
    }
    .padding(.vertical, 3)
  }
}

/// Value column (right-aligned, shrunk to fit like DiaryScaledValueText), label
/// column, bar filling the rest, optional "eaten / target" column.
private struct BalanceRow<Bar: View>: View {
  let value: String
  let valueColor: Color
  let valueSize: CGFloat
  let valueWidth: CGFloat
  let label: String
  let totals: (String, String)?
  @ViewBuilder let bar: () -> Bar

  var body: some View {
    HStack(spacing: 0) {
      Text(value)
        .font(.system(size: valueSize, weight: .bold))
        .foregroundColor(valueColor)
        .lineLimit(1)
        .minimumScaleFactor(0.4)
        .frame(width: valueWidth, alignment: .trailing)
      Spacer().frame(width: valueLabelGap)
      Text(label)
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(HomeWidgetColors.onSurface)
        .lineLimit(1)
        .frame(width: labelWidth, alignment: .leading)
      Spacer().frame(width: barGap)
      bar()
      if let totals {
        Spacer().frame(width: barGap)
        (Text(totals.0).font(.system(size: 11, weight: .bold)).foregroundColor(HomeWidgetColors.onSurface)
          + Text(totals.1).font(.system(size: 11)).foregroundColor(HomeWidgetColors.onSurfaceVariant))
          .lineLimit(1)
          .minimumScaleFactor(0.6)
          .frame(width: totalsWidth, alignment: .trailing)
      }
    }
  }
}

/// DiarySegmentedProgressBar: 4 pills, height 6, gap 3, each filled by its share.
private struct SegmentedBar: View {
  let progress: Double
  let color: Color

  var body: some View {
    HStack(spacing: 3) {
      ForEach(0..<segmentCount, id: \.self) { index in
        let share = (progress - Double(index) / Double(segmentCount)) * Double(segmentCount)
        ProgressPill(progress: min(max(share, 0), 1), color: color, height: 6)
      }
    }
  }
}

/// Rounded track with a leading fill, like Glance's LinearProgressIndicator.
private struct ProgressPill: View {
  let progress: Double
  let color: Color
  let height: CGFloat

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Capsule().fill(HomeWidgetColors.surface)
        Capsule().fill(color).frame(width: geometry.size.width * progress)
      }
    }
    .frame(height: height)
  }
}

private func ratio(_ eaten: Double, _ target: Double) -> Double {
  target <= 0 ? 0 : min(max(eaten / target, 0), 1)
}

private func formatInteger(_ value: Int) -> String {
  NumberFormatter.localizedString(from: NSNumber(value: value), number: .decimal)
}

/// Looks up [key] in this extension's Localizable.strings.
func localized(_ key: String) -> String {
  NSLocalizedString(key, comment: "")
}
