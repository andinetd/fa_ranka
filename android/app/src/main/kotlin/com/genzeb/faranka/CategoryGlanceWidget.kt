package com.genzeb.faranka

import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalContext
import androidx.glance.background
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle

class CategoryGlanceWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            CategoryContent()
        }
    }
}

@Composable
private fun CategoryContent() {
    val context = LocalContext.current
    val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
    val isDark = isDarkMode(context)
    val fg = if (isDark) argbColor(GlanceTokens.FgDark) else argbColor(GlanceTokens.FgLight)
    val muted = if (isDark) argbColor(GlanceTokens.MutedDark) else argbColor(GlanceTokens.MutedLight)
    val track = if (isDark) argbColor(GlanceTokens.TrackDark) else argbColor(GlanceTokens.TrackLight)
    val subBg = subContainerTint(isDark)

    val total = prefs.getString("cat_total", "--") ?: "--"
    val count = prefs.getString("cat_count", "") ?: ""

    WidgetRoot(actionStartActivity(Intent(context, MainActivity::class.java))) {
        WidgetCard {
            // Enhanced header with total amount
            Column(GlanceModifier.fillMaxWidth()) {
                Text(
                    "Monthly Spending",
                    maxLines = 1,
                    style = TextStyle(color = muted, fontSize = 12.sp, fontWeight = FontWeight.Medium),
                )
                Spacer(GlanceModifier.height(4.dp))
                Text(
                    total,
                    maxLines = 1,
                    style = TextStyle(color = fg, fontSize = 28.sp, fontWeight = FontWeight.Bold),
                )
                if (count.isNotEmpty()) {
                    Spacer(GlanceModifier.height(2.dp))
                    MicroLabel(
                        text = count,
                        color = muted,
                    )
                }
            }
            
            Spacer(GlanceModifier.height(14.dp))

            for (i in 1..4) {
                val name = prefs.getString("cat${i}_name", null)
                val amount = prefs.getString("cat${i}_amount", null)
                if (name != null && amount != null) {
                    val dotArgb = prefs.intOr("cat${i}_dot_color", 0xFFF58220.toInt())
                    val progress = prefs.intOr("cat${i}_progress", 0)
                    
                    Column(
                        GlanceModifier
                            .fillMaxWidth()
                            .cornerRadius(10.dp)
                            .background(subBg)
                            .padding(10.dp)
                    ) {
                        // Category name and amount row
                        Row(GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                            CategoryBadge(dotArgb)
                            Spacer(GlanceModifier.width(12.dp))
                            Text(
                                name,
                                GlanceModifier.defaultWeight(),
                                maxLines = 1,
                                style = TextStyle(color = fg, fontSize = 15.sp, fontWeight = FontWeight.Medium),
                            )
                            Spacer(GlanceModifier.width(8.dp))
                            Text(
                                amount,
                                maxLines = 1,
                                style = TextStyle(color = fg, fontSize = 15.sp, fontWeight = FontWeight.Bold),
                            )
                        }
                        
                        Spacer(GlanceModifier.height(6.dp))
                        
                        // Progress bar with category color
                        RoundedProgress(
                            fraction = progress / 1000f,
                            color = argbColor(dotArgb),
                            trackColor = track,
                            barHeight = 6.dp,
                        )
                    }
                    
                    if (i < 4) {
                        Spacer(GlanceModifier.height(6.dp))
                    }
                }
            }
        }
    }
}
