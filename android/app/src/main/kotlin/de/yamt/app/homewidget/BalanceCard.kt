package de.yamt.app.homewidget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.appwidget.LinearProgressIndicator
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ColumnScope
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import de.yamt.app.R
import java.text.NumberFormat
import kotlin.math.abs
import kotlin.math.roundToInt

// Sizes mirror the Diary card: AppSpacing/AppRadius tokens in
// lib/core/constants/app_layout_constants.dart and the column widths in
// diary_nutrition_macro_row.dart / diary_quiet_kcal_row.dart.
private val quietValueWidth = 60.dp // diaryQuietMacroValueWidth
private val totalsValueWidth = 42.dp // _valueWidth (rows with totals)
private val totalsWidth = 68.dp // _totalWidth
private val valueLabelGap = 6.dp // diaryMacroValueLabelGap
private val labelWidth = 44.dp // diaryMacroLabelWidth
private val barGap = 10.dp // AppSpacing.sm
private val macroRowGap = 8.dp // diaryMacroRowGap (AppSpacing.xs)
private const val SEGMENT_COUNT = 4

/**
 * DiaryBalanceShell: surfaceContainerLow, outlineVariant border, radius lg,
 * padding xl. Tapping the card opens the app.
 */
@Composable
internal fun BalanceShell(context: Context, content: @Composable ColumnScope.() -> Unit) {
  Box(
      modifier =
          GlanceModifier.fillMaxWidth()
              .background(HomeWidgetColors.outlineVariant)
              .cornerRadius(16.dp)
              .padding(1.dp)
              .clickable(openAppAction(context, "homewidget://open")),
  ) {
    Column(
        modifier =
            GlanceModifier.fillMaxWidth()
                .background(HomeWidgetColors.surfaceContainerLow)
                .cornerRadius(15.dp)
                .padding(16.dp),
        content = content,
    )
  }
}

/** DiaryDailyBalanceCard in quiet mode; verbose adds the macro totals column. */
@Composable
internal fun BalanceCardContent(context: Context, snapshot: HomeDiarySnapshot) {
  val numbers = NumberFormat.getIntegerInstance()
  val leftKcal = (snapshot.targetKcal - snapshot.eatenKcal).roundToInt()
  val isOverTarget = leftKcal < 0
  val accent = if (isOverTarget) HomeWidgetColors.error else HomeWidgetColors.primary
  val label =
      context.getString(
          if (isOverTarget) R.string.home_widget_over_goal else R.string.home_widget_left_today)

  Text(
      label.uppercase(),
      maxLines = 1,
      style = TextStyle(color = accent, fontWeight = FontWeight.Bold, fontSize = 11.sp),
  )
  Spacer(modifier = GlanceModifier.height(2.dp))
  BalanceRow(
      value = numbers.format(abs(leftKcal)),
      valueColor = accent,
      valueSize = 32f,
      valueChars = 3,
      valueWidth = quietValueWidth,
      label = context.getString(R.string.home_widget_unit_kcal),
  ) { modifier ->
    LinearProgressIndicator(
        progress = ratio(snapshot.eatenKcal, snapshot.targetKcal),
        modifier = modifier.height(10.dp).cornerRadius(5.dp),
        color = HomeWidgetColors.primary,
        backgroundColor = HomeWidgetColors.surface,
    )
  }
  Spacer(modifier = GlanceModifier.height(12.dp))
  MacroRow(context, R.string.home_widget_protein, snapshot.protein, HomeWidgetColors.protein, snapshot.verbose, numbers)
  Spacer(modifier = GlanceModifier.height(macroRowGap))
  MacroRow(context, R.string.home_widget_carbs, snapshot.carbs, HomeWidgetColors.carbs, snapshot.verbose, numbers)
  Spacer(modifier = GlanceModifier.height(macroRowGap))
  MacroRow(context, R.string.home_widget_fat, snapshot.fat, HomeWidgetColors.fat, snapshot.verbose, numbers)
}

/** DiaryNutritionMacroRow: remaining (or +overage) grams, label, 4-segment bar. */
@Composable
private fun MacroRow(
    context: Context,
    labelRes: Int,
    macro: HomeDiarySnapshot.Macro,
    color: ColorProvider,
    showTotal: Boolean,
    numbers: NumberFormat,
) {
  val unit = context.getString(R.string.home_widget_unit_gram)
  val remaining = macro.target - macro.eaten
  val rounded = remaining.roundToInt()
  val value =
      if (remaining < -0.5) "+${numbers.format(-rounded)}$unit"
      else "${numbers.format(maxOf(0, rounded))}$unit"

  Box(modifier = GlanceModifier.fillMaxWidth().padding(vertical = 3.dp)) {
    BalanceRow(
        value = value,
        valueColor = color,
        valueSize = if (showTotal) 16f else 22f,
        valueChars = 4,
        valueWidth = if (showTotal) totalsValueWidth else quietValueWidth,
        label = context.getString(labelRes),
        totals =
            if (showTotal) {
              numbers.format(macro.eaten.roundToInt()) to
                  " / ${numbers.format(macro.target.roundToInt())}$unit"
            } else {
              null
            },
    ) { modifier ->
      SegmentedBar(ratio(macro.eaten, macro.target), color, modifier)
    }
  }
}

/**
 * Value column (right-aligned, shrunk to fit like DiaryScaledValueText), label
 * column, bar filling the rest, optional "eaten / target" column.
 */
@Composable
private fun BalanceRow(
    value: String,
    valueColor: ColorProvider,
    valueSize: Float,
    valueChars: Int,
    valueWidth: androidx.compose.ui.unit.Dp,
    label: String,
    totals: Pair<String, String>? = null,
    bar: @Composable (GlanceModifier) -> Unit,
) {
  Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
    Text(
        value,
        maxLines = 1,
        modifier = GlanceModifier.width(valueWidth),
        style =
            TextStyle(
                color = valueColor,
                fontWeight = FontWeight.Bold,
                fontSize = fitSize(valueSize, value.length, valueChars).sp,
                textAlign = TextAlign.End,
            ),
    )
    Spacer(modifier = GlanceModifier.width(valueLabelGap))
    Text(
        label,
        maxLines = 1,
        modifier = GlanceModifier.width(labelWidth),
        style = TextStyle(color = HomeWidgetColors.onSurface, fontWeight = FontWeight.Bold, fontSize = 12.sp),
    )
    Spacer(modifier = GlanceModifier.width(barGap))
    bar(GlanceModifier.defaultWeight())
    if (totals != null) {
      Spacer(modifier = GlanceModifier.width(barGap))
      Row(modifier = GlanceModifier.width(totalsWidth), horizontalAlignment = Alignment.End) {
        Text(
            totals.first,
            maxLines = 1,
            style = TextStyle(color = HomeWidgetColors.onSurface, fontWeight = FontWeight.Bold, fontSize = 11.sp),
        )
        Text(
            totals.second,
            maxLines = 1,
            style = TextStyle(color = HomeWidgetColors.onSurfaceVariant, fontSize = 11.sp),
        )
      }
    }
  }
}

/** DiarySegmentedProgressBar: 4 pills, height 6, gap 3, each filled by its share. */
@Composable
private fun SegmentedBar(progress: Float, color: ColorProvider, modifier: GlanceModifier) {
  Row(modifier = modifier) {
    for (index in 0 until SEGMENT_COUNT) {
      if (index > 0) {
        Spacer(modifier = GlanceModifier.width(3.dp))
      }
      val segmentFill = ((progress - index.toFloat() / SEGMENT_COUNT) * SEGMENT_COUNT).coerceIn(0f, 1f)
      LinearProgressIndicator(
          progress = segmentFill,
          modifier = GlanceModifier.defaultWeight().height(6.dp).cornerRadius(3.dp),
          color = color,
          backgroundColor = HomeWidgetColors.surface,
      )
    }
  }
}

private fun ratio(eaten: Double, target: Double): Float =
    if (target <= 0) 0f else (eaten / target).toFloat().coerceIn(0f, 1f)

/** Shrinks [base] so [length] characters take the room [fitChars] would at full size. */
private fun fitSize(base: Float, length: Int, fitChars: Int): Float =
    if (length <= fitChars) base else base * fitChars / length
