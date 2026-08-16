package com.genzeb.faranka

import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.action.Action
import androidx.glance.action.clickable
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ColumnScope
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider

object GlanceTokens {
    // Brand & Investment
    val BrandGreen: Int = 0xFF79AE6F.toInt()
    
    // Vibrant palette - Light mode
    val CreditLight: Int = 0xFF10B981.toInt()      // Emerald
    val DebitLight: Int = 0xFFEF4444.toInt()       // Coral red
    val WarnLight: Int = 0xFFF59E0B.toInt()        // Amber
    val IndigoLight: Int = 0xFF4F46E5.toInt()      // Indigo
    val PurpleLight: Int = 0xFF8B5CF6.toInt()      // Purple
    
    // Vibrant palette - Dark mode
    val CreditDark: Int = 0xFF6EE7B7.toInt()       // Bright emerald
    val DebitDark: Int = 0xFFFCA5A5.toInt()        // Light coral
    val WarnDark: Int = 0xFFFCD34D.toInt()         // Light amber
    val IndigoDark: Int = 0xFF818CF8.toInt()       // Bright indigo
    val PurpleDark: Int = 0xFFA78BFA.toInt()       // Bright purple

    // Neutral background & text - Light mode
    val CardBgLight: Int = 0xFFFFFFFF.toInt()
    val FgLight: Int = 0xFF1F2937.toInt()
    val MutedLight: Int = 0xFF6B7280.toInt()
    val SubContainerLight: Int = 0xFFF8F9FA.toInt()   // Lighter gray
    val TrackLight: Int = 0xFFE5E7EB.toInt()
    val HairlineLight: Int = 0xFFD1D5DB.toInt()       // Darker divider

    // Neutral background & text - Dark mode
    val CardBgDark: Int = 0xFF111827.toInt()          // Darker background
    val FgDark: Int = 0xFFF9FAFB.toInt()
    val MutedDark: Int = 0xFF9CA3AF.toInt()
    val SubContainerDark: Int = 0xFF1F2937.toInt()    // Lighter dark gray
    val TrackDark: Int = 0xFF374151.toInt()           // Lighter track
    val HairlineDark: Int = 0xFF374151.toInt()

    // Gradient starts
    val GradientStart1: Int = 0xFF4F46E5.toInt()      // Indigo
    val GradientEnd1: Int = 0xFF8B5CF6.toInt()        // Purple
    val GradientStart2: Int = 0xFF06B6D4.toInt()      // Cyan
    val GradientEnd2: Int = 0xFF0EA5E9.toInt()        // Blue

    // Category palette - vibrant & accessible
    val CategoryColors = intArrayOf(
        0xFFF58220.toInt(),  // Orange
        0xFF10B981.toInt(),  // Emerald
        0xFF3B82F6.toInt(),  // Blue
        0xFF8B5CF6.toInt(),  // Purple
        0xFFEF4444.toInt(),  // Red
        0xFF1ABC9C.toInt(),  // Teal
        0xFFF59E0B.toInt(),  // Amber
        0xFF6366F1.toInt(),  // Indigo
    )
}

fun isDarkMode(context: Context): Boolean {
    return (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
        Configuration.UI_MODE_NIGHT_YES
}

fun SharedPreferences.intOr(key: String, default: Int): Int {
    return try {
        getLong(key, default.toLong()).toInt()
    } catch (_: Exception) {
        getInt(key, default)
    }
}

fun argbColor(argb: Int): ColorProvider = ColorProvider(Color(argb))

fun badgeTint(argb: Int): ColorProvider = ColorProvider(Color(argb).copy(alpha = 0.25f))

fun cardBgColor(isDark: Boolean): ColorProvider =
    if (isDark) argbColor(GlanceTokens.CardBgDark) else argbColor(GlanceTokens.CardBgLight)

fun subContainerTint(isDark: Boolean): ColorProvider =
    if (isDark) argbColor(GlanceTokens.SubContainerDark) else argbColor(GlanceTokens.SubContainerLight)

fun creditColor(isDark: Boolean): ColorProvider =
    if (isDark) argbColor(GlanceTokens.CreditDark) else argbColor(GlanceTokens.CreditLight)

fun debitColor(isDark: Boolean): ColorProvider =
    if (isDark) argbColor(GlanceTokens.DebitDark) else argbColor(GlanceTokens.DebitLight)

@Composable
fun WidgetRoot(
    action: Action,
    content: @Composable () -> Unit,
) {
    Box(
        GlanceModifier
            .fillMaxSize()
            .padding(10.dp)
            .clickable(action)
    ) {
        content()
    }
}

@Composable
fun WidgetCard(
    modifier: GlanceModifier = GlanceModifier,
    content: @Composable ColumnScope.() -> Unit,
) {
    val context = LocalContext.current
    val isDark = isDarkMode(context)
    Column(
        modifier
            .fillMaxSize()
            .cornerRadius(24.dp)
            .background(cardBgColor(isDark))
            .padding(16.dp),
        content = content,
    )
}

@Composable
fun HeaderRow(
    label: String,
    labelColor: ColorProvider,
    modifier: GlanceModifier = GlanceModifier,
    trailing: (@Composable () -> Unit)? = null,
) {
    Row(
        GlanceModifier.fillMaxWidth().then(modifier),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            label,
            GlanceModifier.defaultWeight(),
            maxLines = 1,
            style = TextStyle(color = labelColor, fontSize = 13.sp, fontWeight = FontWeight.Medium),
        )
        trailing?.invoke()
    }
}

@Composable
fun TintedChip(
    text: String,
    fg: ColorProvider,
    bg: ColorProvider,
    modifier: GlanceModifier = GlanceModifier,
) {
    Box(
        modifier
            .background(bg)
            .cornerRadius(10.dp)
            .padding(horizontal = 10.dp, vertical = 4.dp),
    ) {
        Text(
            text,
            maxLines = 1,
            style = TextStyle(color = fg, fontSize = 12.sp, fontWeight = FontWeight.Bold),
        )
    }
}

@Composable
fun CategoryBadge(colorArgb: Int) {
    Box(
        GlanceModifier
            .size(28.dp)
            .cornerRadius(7.dp)
            .background(badgeTint(colorArgb)),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            GlanceModifier
                .size(12.dp)
                .cornerRadius(6.dp)
                .background(argbColor(colorArgb)),
        ) { }
    }
}

@Composable
fun CategoryBadgeLarge(colorArgb: Int) {
    Box(
        GlanceModifier
            .size(36.dp)
            .cornerRadius(10.dp)
            .background(badgeTint(colorArgb)),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            GlanceModifier
                .size(16.dp)
                .cornerRadius(8.dp)
                .background(argbColor(colorArgb)),
        ) { }
    }
}

@Composable
fun StatBlock(
    label: String,
    value: String,
    fg: ColorProvider,
    muted: ColorProvider,
    tint: ColorProvider,
    modifier: GlanceModifier = GlanceModifier,
) {
    Column(
        modifier
            .cornerRadius(14.dp)
            .background(tint)
            .padding(horizontal = 14.dp, vertical = 10.dp),
    ) {
        Text(
            label,
            maxLines = 1,
            style = TextStyle(color = muted, fontSize = 11.sp, fontWeight = FontWeight.Medium),
        )
        Spacer(GlanceModifier.height(3.dp))
        Text(
            value,
            maxLines = 1,
            style = TextStyle(color = fg, fontSize = 16.sp, fontWeight = FontWeight.Bold),
        )
    }
}

@Composable
fun RoundedProgress(
    fraction: Float,
    color: ColorProvider,
    trackColor: ColorProvider,
    modifier: GlanceModifier = GlanceModifier,
    barHeight: Dp = 5.dp,
) {
    val trackWidth = LocalSize.current.width
    val fillWidth =
        if (trackWidth == Dp.Unspecified) Dp.Unspecified
        else trackWidth * fraction.coerceIn(0f, 1f)
    Box(
        modifier
            .fillMaxWidth()
            .height(barHeight)
            .background(trackColor)
            .cornerRadius(barHeight / 2),
    ) {
        if (fillWidth != Dp.Unspecified && fillWidth > 0.dp) {
            Box(
                GlanceModifier
                    .width(fillWidth)
                    .fillMaxHeight()
                    .background(color)
                    .cornerRadius(barHeight / 2),
            ) { }
        }
    }
}

@Composable
fun HairlineDivider(color: ColorProvider) {
    Box(GlanceModifier.fillMaxWidth().height(1.dp).background(color)) { }
}

@Composable
fun LiveDot() {
    Box(
        GlanceModifier
            .size(6.dp)
            .cornerRadius(3.dp)
            .background(argbColor(GlanceTokens.BrandGreen)),
    ) { }
}

@Composable
fun BrandBadge() {
    Box(
        GlanceModifier
            .size(24.dp)
            .cornerRadius(7.dp)
            .background(argbColor(GlanceTokens.BrandGreen)),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            "G",
            style = TextStyle(color = argbColor(0xFFFFFFFF.toInt()), fontSize = 13.sp, fontWeight = FontWeight.Bold),
        )
    }
}

@Composable
fun CircularProgress(
    fraction: Float,
    size: Dp = 48.dp,
    color: ColorProvider,
    trackColor: ColorProvider,
) {
    Box(
        GlanceModifier
            .size(size)
            .background(trackColor)
            .cornerRadius(size / 2),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            GlanceModifier
                .size(size * 0.75f)
                .background(color)
                .cornerRadius(size * 0.375f),
        ) { }
    }
}

@Composable
fun MicroLabel(
    text: String,
    color: ColorProvider,
    modifier: GlanceModifier = GlanceModifier,
) {
    Text(
        text,
        modifier,
        maxLines = 1,
        style = TextStyle(color = color, fontSize = 9.sp, fontWeight = FontWeight.Medium),
    )
}
