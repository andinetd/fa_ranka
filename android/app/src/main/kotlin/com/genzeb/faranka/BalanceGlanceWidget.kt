package com.genzeb.faranka

import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalContext
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionStartActivity
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

class BalanceGlanceWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            BalanceContent()
        }
    }
}

@Composable
private fun BalanceContent() {
    val context = LocalContext.current
    val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
    val isDark = isDarkMode(context)
    val fg = if (isDark) argbColor(GlanceTokens.FgDark) else argbColor(GlanceTokens.FgLight)
    val muted = if (isDark) argbColor(GlanceTokens.MutedDark) else argbColor(GlanceTokens.MutedLight)
    val tint = subContainerTint(isDark)

    val cashflow = prefs.getString("balance_cashflow", "") ?: ""
    val cashflowArgb = prefs.intOr("balance_cashflow_color", GlanceTokens.WarnLight)
    val creditColor = if (isDark) argbColor(GlanceTokens.CreditDark) else argbColor(GlanceTokens.CreditLight)
    val debitColor = if (isDark) argbColor(GlanceTokens.DebitDark) else argbColor(GlanceTokens.DebitLight)

    WidgetRoot(actionStartActivity(Intent(context, MainActivity::class.java))) {
        WidgetCard {
            HeaderRow(
                label = prefs.getString("balance_title", "Total Balance") ?: "Total Balance",
                labelColor = muted,
                trailing = {
                    if (cashflow.isNotEmpty()) {
                        TintedChip(
                            text = cashflow,
                            fg = argbColor(cashflowArgb),
                            bg = badgeTint(cashflowArgb),
                        )
                    }
                },
            )

            Spacer(GlanceModifier.height(12.dp))

            Row(GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.Bottom) {
                Text(
                    prefs.getString("balance_prefix", "ETB ") ?: "ETB ",
                    GlanceModifier.padding(bottom = 4.dp),
                    style = TextStyle(color = fg, fontSize = 18.sp, fontWeight = FontWeight.Medium),
                )
                Text(
                    prefs.getString("balance_amount", "--") ?: "--",
                    GlanceModifier.defaultWeight().padding(start = 4.dp),
                    maxLines = 1,
                    style = TextStyle(color = fg, fontSize = 44.sp, fontWeight = FontWeight.Bold),
                )
            }

            Spacer(GlanceModifier.height(16.dp))

            // Enhanced stats with modern pill design
            Row(GlanceModifier.fillMaxWidth()) {
                // Sent pill
                StatBlock(
                    label = "SENT",
                    value = prefs.getString("balance_sent", "--") ?: "--",
                    fg = debitColor,
                    muted = muted,
                    tint = badgeTint(GlanceTokens.DebitLight),
                    modifier = GlanceModifier.defaultWeight(),
                )
                Spacer(GlanceModifier.width(10.dp))
                // Received pill
                StatBlock(
                    label = "RECEIVED",
                    value = prefs.getString("balance_received", "--") ?: "--",
                    fg = creditColor,
                    muted = muted,
                    tint = badgeTint(GlanceTokens.CreditLight),
                    modifier = GlanceModifier.defaultWeight(),
                )
            }

            val lastSync = prefs.getString("balance_last_sync", "") ?: ""
            if (lastSync.isNotEmpty()) {
                Spacer(GlanceModifier.height(10.dp))
                MicroLabel(
                    text = lastSync,
                    color = muted,
                )
            }
        }
    }
}
