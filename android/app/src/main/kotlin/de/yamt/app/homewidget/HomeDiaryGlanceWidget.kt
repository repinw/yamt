package de.yamt.app.homewidget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.currentState
import androidx.glance.layout.Column
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.wrapContentHeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import de.yamt.app.R
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import org.json.JSONObject

/**
 * Key `home_widget`'s Flutter side saves the snapshot JSON under. Must match
 * `homeWidgetSnapshotDataKey` in
 * `lib/features/home_widget/data/home_widget_plugin_bridge.dart`.
 */
private const val SNAPSHOT_KEY = "diary_home_widget_snapshot"

/**
 * Home-screen widget mirroring the Diary daily balance card
 * (`DiaryDailyBalanceCard`, quiet mode) and the compact quick-eat bar below it.
 */
class HomeDiaryGlanceWidget : GlanceAppWidget() {
  override val stateDefinition = HomeWidgetGlanceStateDefinition()

  override suspend fun provideGlance(context: Context, id: GlanceId) {
    // currentState() inside the composition, not a one-time read: an update
    // while a Glance session is still running only recomposes, so a state
    // read before provideContent would keep showing the old snapshot.
    provideContent { HomeDiaryWidgetContent(context, currentState()) }
  }
}

@Composable
private fun HomeDiaryWidgetContent(context: Context, state: HomeWidgetGlanceState) {
  val snapshot =
      state.preferences.getString(SNAPSHOT_KEY, null)?.let {
        runCatching { HomeDiarySnapshot.fromJson(JSONObject(it)) }.getOrNull()
      }

  Column(modifier = GlanceModifier.fillMaxWidth().wrapContentHeight()) {
    BalanceShell(context) {
      if (snapshot == null) {
        Text(
            context.getString(R.string.home_widget_no_data),
            style = TextStyle(color = HomeWidgetColors.onSurfaceVariant),
        )
      } else {
        BalanceCardContent(context, snapshot)
      }
    }
    // Same gap the Diary page leaves between the card and the quick-eat bar.
    Spacer(modifier = GlanceModifier.height(12.dp))
    QuickEatBar(context)
  }
}
