package com.example.maruthi_eats_admin

import android.animation.ValueAnimator
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.text.TextUtils
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.view.animation.LinearInterpolator
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

/** What the alert shows. Everything except [orderNumber] is optional. */
data class OrderAlertData(
    val orderNumber: String,
    val total: String? = null,
    val items: String? = null,
    val payment: String? = null
)

/**
 * Native full-screen "new order" alert drawn ABOVE every other app
 * (needs the "Display over other apps" permission). Used when the phone is
 * unlocked and the admin app is not on screen - the one situation where
 * Android refuses to turn a notification into a full-screen activity.
 *
 * Plays the order sound in a loop (alarm volume) until the user taps a button.
 */
object OrderAlertOverlay {
    private const val TAG = "OrderAlertOverlay"
    private const val AUTO_DISMISS_MS = 120_000L

    // Brand colours (same as the Flutter app theme)
    private val MAROON = Color.parseColor("#800020")
    private val MAROON_DARK = Color.parseColor("#5C0017")
    private val GOLD = Color.parseColor("#D4AF37")
    private val TEXT_DARK = Color.parseColor("#333333")
    private val GREEN = Color.parseColor("#3A7D44")
    private val AMBER = Color.parseColor("#B8860B")

    private val handler = Handler(Looper.getMainLooper())
    private var appContext: Context? = null
    private var root: View? = null
    private var player: MediaPlayer? = null
    private var pulse: ValueAnimator? = null
    private var count = 0

    // Views that change when another order arrives while the alert is open
    private var badgeView: TextView? = null
    private var orderNumView: TextView? = null
    private var paymentView: TextView? = null
    private var itemsView: TextView? = null
    private var itemsDivider: View? = null
    private var totalRow: View? = null
    private var totalView: TextView? = null

    private val autoDismiss = Runnable { dismiss() }

    // The Flutter FCM handler also posts a normal notification a moment later.
    // While / right after the overlay is up it is removed so the sound is not doubled.
    private val cancelNotifications = Runnable {
        try {
            val ctx = appContext ?: return@Runnable
            (ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancelAll()
        } catch (e: Exception) {
            Log.w(TAG, "cancelAll failed: $e")
        }
    }

    fun show(context: Context, data: OrderAlertData) {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            handler.post { show(context, data) }
            return
        }
        val ctx = context.applicationContext
        appContext = ctx
        count++

        if (root != null) {
            // Another order arrived while the alert is open: just update it.
            bind(data)
        } else {
            try {
                addWindow(ctx, data)
//                startSound(ctx)
                startVibration(ctx)
            } catch (e: Exception) {
                Log.e(TAG, "Could not show overlay: $e")
                dismiss()
                return
            }
        }
        handler.removeCallbacks(autoDismiss)
        handler.postDelayed(autoDismiss, AUTO_DISMISS_MS)
        scheduleNotificationCleanup()
    }

    fun dismiss() {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            handler.post { dismiss() }
            return
        }
        handler.removeCallbacks(autoDismiss)
        pulse?.cancel()
        pulse = null
        val view = root
        if (view != null) {
            try {
                val wm = view.context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                wm.removeView(view)
            } catch (e: Exception) {
                Log.w(TAG, "removeView failed: $e")
            }
        }
        root = null
        badgeView = null
        orderNumView = null
        paymentView = null
        itemsView = null
        itemsDivider = null
        totalRow = null
        totalView = null
        count = 0
        stopSound()
        stopVibration()
        if (view != null) scheduleNotificationCleanup()
    }

    private fun scheduleNotificationCleanup() {
        handler.removeCallbacks(cancelNotifications)
        for (delay in longArrayOf(300, 1000, 2500, 5000, 9000)) {
            handler.postDelayed(cancelNotifications, delay)
        }
    }

    // ------------------------------------------------------------------ UI

    @Suppress("DEPRECATION")
    private fun addWindow(ctx: Context, data: OrderAlertData) {
        val wm = ctx.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val view = buildView(ctx, data)

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }
        val params = WindowManager.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT,
            type,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            PixelFormat.TRANSLUCENT
        )
        view.alpha = 0f
        wm.addView(view, params)
        root = view
        view.animate().alpha(1f).setDuration(250).start()
    }

    private fun dp(ctx: Context, value: Int): Int =
        TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            ctx.resources.displayMetrics
        ).toInt()

    private fun rounded(
        ctx: Context,
        color: Int,
        radiusDp: Int,
        strokeColor: Int? = null,
        strokeDp: Int = 0
    ) = GradientDrawable().apply {
        setColor(color)
        cornerRadius = dp(ctx, radiusDp).toFloat()
        if (strokeColor != null) setStroke(dp(ctx, strokeDp), strokeColor)
    }

    private fun label(
        ctx: Context,
        text: String,
        sp: Float,
        color: Int,
        bold: Boolean = false
    ) = TextView(ctx).apply {
        this.text = text
        setTextColor(color)
        setTextSize(TypedValue.COMPLEX_UNIT_SP, sp)
        if (bold) setTypeface(null, Typeface.BOLD)
    }

    private fun lp(w: Int, h: Int, top: Int = 0, ctx: Context? = null) =
        LinearLayout.LayoutParams(w, h).apply {
            if (ctx != null) topMargin = dp(ctx, top)
        }

    private fun buildView(ctx: Context, data: OrderAlertData): View {
        val match = ViewGroup.LayoutParams.MATCH_PARENT
        val wrap = ViewGroup.LayoutParams.WRAP_CONTENT

        val layout = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            background = GradientDrawable(
                GradientDrawable.Orientation.TOP_BOTTOM,
                intArrayOf(MAROON, MAROON_DARK, Color.parseColor("#12020A"))
            )
            setPadding(dp(ctx, 20), dp(ctx, 52), dp(ctx, 20), dp(ctx, 28))
            isClickable = true // swallow touches so nothing behind is pressed
        }

        // ---- "NEW ORDER" pill
        val badge = label(ctx, "NEW ORDER", 12f, GOLD, bold = true).apply {
            letterSpacing = 0.15f
            gravity = Gravity.CENTER
            background = rounded(ctx, Color.parseColor("#26D4AF37"), 20, GOLD, 1)
            setPadding(dp(ctx, 16), dp(ctx, 6), dp(ctx, 16), dp(ctx, 6))
        }
        badgeView = badge
        layout.addView(badge, lp(wrap, wrap).apply { gravity = Gravity.CENTER_HORIZONTAL })

        // ---- Pulsing icon
        val pulseBox = FrameLayout(ctx)
        val ring1 = ringView(ctx)
        val ring2 = ringView(ctx)
        val iconCircle = label(ctx, "\uD83C\uDF7D\uFE0F", 40f, MAROON).apply {
            gravity = Gravity.CENTER
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(GOLD)
            }
        }
        pulseBox.addView(ring1, FrameLayout.LayoutParams(dp(ctx, 96), dp(ctx, 96), Gravity.CENTER))
        pulseBox.addView(ring2, FrameLayout.LayoutParams(dp(ctx, 96), dp(ctx, 96), Gravity.CENTER))
        pulseBox.addView(iconCircle, FrameLayout.LayoutParams(dp(ctx, 96), dp(ctx, 96), Gravity.CENTER))
        layout.addView(
            pulseBox,
            lp(dp(ctx, 170), dp(ctx, 170), 8, ctx).apply { gravity = Gravity.CENTER_HORIZONTAL }
        )
        startPulse(ring1, ring2)

        // ---- Title
        val title = label(ctx, "New Order Received!", 26f, GOLD, bold = true).apply {
            typeface = Typeface.create("serif", Typeface.BOLD)
            gravity = Gravity.CENTER
        }
        layout.addView(title, lp(match, wrap))

        // ---- Card (scrolls if the order is long)
        val card = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            background = rounded(ctx, Color.WHITE, 24)
            setPadding(dp(ctx, 20), dp(ctx, 18), dp(ctx, 20), dp(ctx, 18))
        }

        // order number + payment chip
        val topRow = LinearLayout(ctx).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        val orderNum = label(ctx, "", 13f, Color.GRAY, bold = true).apply { letterSpacing = 0.08f }
        orderNumView = orderNum
        topRow.addView(orderNum, LinearLayout.LayoutParams(0, wrap, 1f))
        val payment = label(ctx, "", 11f, Color.WHITE, bold = true).apply {
            gravity = Gravity.CENTER
            setPadding(dp(ctx, 12), dp(ctx, 5), dp(ctx, 12), dp(ctx, 5))
            visibility = View.GONE
        }
        paymentView = payment
        topRow.addView(payment, LinearLayout.LayoutParams(wrap, wrap))
        card.addView(topRow, lp(match, wrap))

        // items
        val divider1 = divider(ctx)
        itemsDivider = divider1
        card.addView(divider1, lp(match, dp(ctx, 1), 14, ctx))
        val items = label(ctx, "", 17f, TEXT_DARK, bold = true).apply {
            setLineSpacing(0f, 1.25f)
            maxLines = 8
            ellipsize = TextUtils.TruncateAt.END
        }
        itemsView = items
        card.addView(items, lp(match, wrap, 14, ctx))

        // total
        val divider2 = divider(ctx)
        card.addView(divider2, lp(match, dp(ctx, 1), 14, ctx))
        val total = LinearLayout(ctx).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        total.addView(
            label(ctx, "TOTAL AMOUNT", 12f, Color.GRAY, bold = true).apply { letterSpacing = 0.08f },
            LinearLayout.LayoutParams(0, wrap, 1f)
        )
        val totalText = label(ctx, "", 28f, MAROON, bold = true)
        totalView = totalText
        total.addView(totalText, LinearLayout.LayoutParams(wrap, wrap))
        totalRow = total
        card.addView(total, lp(match, wrap, 12, ctx))

        val scroll = ScrollView(ctx).apply {
            isVerticalScrollBarEnabled = false
            addView(card, ViewGroup.LayoutParams(match, wrap))
        }
        layout.addView(scroll, LinearLayout.LayoutParams(match, 0, 1f).apply {
            topMargin = dp(ctx, 20)
        })
        card.translationY = dp(ctx, 40).toFloat()
        card.animate().translationY(0f).setDuration(350).start()

        // ---- Buttons
        val viewButton = Button(ctx).apply {
            text = "VIEW ORDER"
            setTextColor(MAROON)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 17f)
            setTypeface(null, Typeface.BOLD)
            letterSpacing = 0.05f
            stateListAnimator = null
            background = rounded(ctx, GOLD, 18)
            setOnClickListener { openApp(ctx) }
        }
        layout.addView(viewButton, lp(match, dp(ctx, 60), 20, ctx))

        val dismissButton = Button(ctx).apply {
            text = "Dismiss for now"
            isAllCaps = false
            setTextColor(Color.parseColor("#B3FFFFFF"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            stateListAnimator = null
            setBackgroundColor(Color.TRANSPARENT)
            setOnClickListener { dismiss() }
        }
        layout.addView(dismissButton, lp(match, dp(ctx, 48), 6, ctx))

        // fill in the order details (also used when more orders arrive)
        bind(data)
        return layout
    }

    private fun divider(ctx: Context) = View(ctx).apply {
        setBackgroundColor(Color.parseColor("#1F000000"))
    }

    private fun ringView(ctx: Context) = View(ctx).apply {
        background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(Color.TRANSPARENT)
            setStroke(dp(ctx, 3), GOLD)
        }
        alpha = 0f
    }

    /** Fills / refreshes the order details in the already built views. */
    private fun bind(data: OrderAlertData) {
        val ctx = appContext ?: return
        badgeView?.text = if (count > 1) "$count NEW ORDERS" else "NEW ORDER"
        orderNumView?.text = "ORDER #${data.orderNumber}"

        val hasItems = !data.items.isNullOrBlank()
        itemsView?.text = data.items ?: ""
        itemsView?.visibility = if (hasItems) View.VISIBLE else View.GONE
        itemsDivider?.visibility = if (hasItems) View.VISIBLE else View.GONE

        val hasTotal = !data.total.isNullOrBlank()
        totalRow?.visibility = if (hasTotal) View.VISIBLE else View.GONE
        totalView?.text = "\u20B9${data.total}"

        val pay = data.payment
        paymentView?.apply {
            if (pay.isNullOrBlank()) {
                visibility = View.GONE
            } else {
                visibility = View.VISIBLE
                if (pay.equals("UPI", ignoreCase = true)) {
                    text = "UPI"
                    background = rounded(ctx, GREEN, 20)
                } else {
                    text = "CASH ON DELIVERY"
                    background = rounded(ctx, AMBER, 20)
                }
            }
        }
    }

    private fun startPulse(ring1: View, ring2: View) {
        pulse?.cancel()
        pulse = ValueAnimator.ofFloat(0f, 1f).apply {
            duration = 1800
            repeatCount = ValueAnimator.INFINITE
            interpolator = LinearInterpolator()
            addUpdateListener { a ->
                val t = a.animatedValue as Float
                applyRing(ring1, t)
                applyRing(ring2, (t + 0.5f) % 1f)
            }
            start()
        }
    }

    private fun applyRing(v: View, t: Float) {
        val s = 1f + t * 0.75f
        v.scaleX = s
        v.scaleY = s
        v.alpha = 0.6f * (1f - t)
    }

    private fun openApp(ctx: Context) {
        try {
            val intent = Intent(ctx, MainActivity::class.java).addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
            // Start while the overlay is still visible, then remove it.
            ctx.startActivity(intent)
        } catch (e: Exception) {
            Log.w(TAG, "Could not open app: $e")
        }
        dismiss()
    }

    // --------------------------------------------------------------- Sound

    private fun startSound(ctx: Context) {
        stopSound()
        try {
            val mp = MediaPlayer()
            mp.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
            val resId = ctx.resources.getIdentifier("notification", "raw", ctx.packageName)
            if (resId != 0) {
                ctx.resources.openRawResourceFd(resId).use { afd ->
                    mp.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                }
            } else {
                mp.setDataSource(ctx, RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM))
            }
            mp.isLooping = true
            mp.setOnPreparedListener { it.start() }
            mp.setOnErrorListener { _, _, _ ->
                stopSound()
                true
            }
            mp.prepareAsync()
            player = mp
        } catch (e: Exception) {
            Log.w(TAG, "Could not play sound: $e")
            stopSound()
        }
    }

    private fun stopSound() {
        val mp = player ?: return
        player = null
        try {
            mp.stop()
        } catch (_: Exception) {
        }
        try {
            mp.release()
        } catch (_: Exception) {
        }
    }

    @Suppress("DEPRECATION")
    private fun startVibration(ctx: Context) {
        try {
            val vibrator = ctx.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator ?: return
            val pattern = longArrayOf(0, 700, 500)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, 0))
            } else {
                vibrator.vibrate(pattern, 0)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Could not vibrate: $e")
        }
    }

    @Suppress("DEPRECATION")
    private fun stopVibration() {
        try {
            val ctx = appContext ?: return
            (ctx.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator)?.cancel()
        } catch (_: Exception) {
        }
    }
}