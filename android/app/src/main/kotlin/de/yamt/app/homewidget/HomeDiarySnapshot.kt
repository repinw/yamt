package de.yamt.app.homewidget

import org.json.JSONObject

/**
 * Snapshot Flutter writes for the widget. Field names match
 * `HomeWidgetSnapshot.toJson` in
 * `lib/features/home_widget/application/home_widget_snapshot.dart`.
 */
internal data class HomeDiarySnapshot(
    val verbose: Boolean,
    val eatenKcal: Double,
    val targetKcal: Double,
    val protein: Macro,
    val carbs: Macro,
    val fat: Macro,
) {
  /** Eaten and target grams of one macro. */
  data class Macro(val eaten: Double, val target: Double)

  companion object {
    fun fromJson(json: JSONObject) =
        HomeDiarySnapshot(
            verbose = json.optBoolean("verbose", false),
            eatenKcal = json.getDouble("eaten_kcal"),
            targetKcal = json.getDouble("target_kcal"),
            protein = Macro(json.getDouble("protein_grams"), json.getDouble("protein_goal_grams")),
            carbs = Macro(json.getDouble("carbs_grams"), json.getDouble("carbs_goal_grams")),
            fat = Macro(json.getDouble("fat_grams"), json.getDouble("fat_goal_grams")),
        )
  }
}
