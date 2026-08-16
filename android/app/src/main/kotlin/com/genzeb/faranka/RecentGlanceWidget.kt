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
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle

class RecentGlanceWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            RecentContent()
        }
    }
}

@Composable
private fun RecentContent() {
    val context = LocalContext.current
    val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
    val isDark = isDarkMode(context)
    val fg = if (isDark) argbColor(GlanceTokens.FgDark) else argbColor(GlanceTokens.FgLight)
    val muted = if (isDark) argbColor(GlanceTokens.MutedDark) else argbColor(GlanceTokens.MutedLight)
    val credit = creditColor(isDark)
    val debit = debitColor(isDark)
    val subBg = subContainerTint(isDark)

    WidgetRoot(actionStartActivity(Intent(context, MainActivity::class.java))) {
        WidgetCard {
            HeaderRow(
                label = "Recent Transactions",
                labelColor = muted,
                trailing = { BrandBadge() },
            )
            Spacer(GlanceModifier.height(12.dp))

            for (i in 1..3) {
                val cat = prefs.getString("recent_txn${i}_cat", null)
                val amount = prefs.getString("recent_txn${i}_amount", null)
                if (cat != null && amount != null) {
                    val direction = prefs.getString("recent_txn${i}_direction", "debit")
                    val amountColor = if (direction == "credit") credit else debit
                    val dotArgb = prefs.intOr("recent_txn${i}_dot_color", 0xFFF58220.toInt())
                    
                    // Transaction row in a subtle card
                    Row(
                        GlanceModifier
                            .fillMaxWidth()
                            .cornerRadius(10.dp)
                            .background(subBg)
                            .padding(10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        CategoryBadge(dotArgb)
                        Spacer(GlanceModifier.width(12.dp))
                        Text(
                            cat,
                            GlanceModifier.defaultWeight(),
                            maxLines = 1,
                            style = TextStyle(color = fg, fontSize = 15.sp, fontWeight = FontWeight.Medium),
                        )
                        Spacer(GlanceModifier.width(8.dp))
                        Text(
                            amount,
                            maxLines = 1,
                            style = TextStyle(color = amountColor, fontSize = 15.sp, fontWeight = FontWeight.Bold),
                        )
                    }
                    if (i < 3) {
                        Spacer(GlanceModifier.height(6.dp))
                    }
                }
            }
        }
    }
}
