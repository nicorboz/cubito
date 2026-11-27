package fr.cubemagique.cube_magique.avatar

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.util.AttributeSet
import android.view.ViewGroup
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout

/** Expressions disponibles pour l'avatar Cubi. */
enum class CubiExpression(val jsName: String) {
    JOYEUX("joyeux"),
    RIRE("rire"),
    CLIN("clin"),
    SURPRIS("surpris"),
    TRISTE("triste"),
    DODO("dodo"),
}

/**
 * Avatar 3D animé « Cubi » (cube-puzzle avec visage).
 *
 * Affiche assets/cubi/index.html dans une WebView transparente, 100 % hors ligne
 * (Three.js est inclus dans le fichier, aucune permission INTERNET requise).
 *
 * Utilisation XML :
 *   <com.example.app.avatar.CubiAvatarView
 *       android:id="@+id/cubiAvatar"
 *       android:layout_width="160dp"
 *       android:layout_height="160dp" />
 *
 * Utilisation code :
 *   cubiAvatar.setExpression(CubiExpression.RIRE)
 *   cubiAvatar.poke()                       // saut + rire + tour de cube
 *   cubiAvatar.onPoke = { /* l'enfant a touché l'avatar */ }
 */
class CubiAvatarView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
) : FrameLayout(context, attrs, defStyleAttr) {

    /** Appelé (sur le thread UI) quand l'utilisateur touche l'avatar. */
    var onPoke: (() -> Unit)? = null

    /** Appelé (sur le thread UI) quand l'avatar est chargé et prêt. */
    var onReady: (() -> Unit)? = null

    private val mainHandler = Handler(Looper.getMainLooper())
    private val pendingJs = mutableListOf<String>()
    private var isReady = false
    private var currentExpression: CubiExpression = CubiExpression.JOYEUX

    private val webView: WebView = WebView(context)

    init {
        setupWebView()
        addView(webView, LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun setupWebView() {
        webView.setBackgroundColor(Color.TRANSPARENT)
        webView.setLayerType(LAYER_TYPE_HARDWARE, null)
        webView.isVerticalScrollBarEnabled = false
        webView.isHorizontalScrollBarEnabled = false
        webView.overScrollMode = OVER_SCROLL_NEVER

        with(webView.settings) {
            javaScriptEnabled = true
            domStorageEnabled = true
            mediaPlaybackRequiresUserGesture = true
            // file:///android_asset reste accessible même avec allowFileAccess = false
            allowFileAccess = false
            allowContentAccess = false
            setSupportZoom(false)
            builtInZoomControls = false
            displayZoomControls = false
        }

        webView.webViewClient = object : WebViewClient() {
            // Bloque toute navigation hors de l'avatar
            override fun shouldOverrideUrlLoading(view: WebView, request: android.webkit.WebResourceRequest) = true
        }
        webView.webChromeClient = WebChromeClient()
        webView.addJavascriptInterface(Bridge(), "CubiBridge")
        webView.loadUrl(ASSET_URL)
    }

    /** Change l'expression du visage (transition animée). */
    fun setExpression(expression: CubiExpression) {
        currentExpression = expression
        runJs("Cubi.setExpression('${expression.jsName}')")
    }

    fun getExpression(): CubiExpression = currentExpression

    /** Fait sauter l'avatar en riant, avec un tour de cube. */
    fun poke() = runJs("Cubi.poke()")

    /** Arrête / relance l'animation (avatar caché par un autre écran : économise le processeur). */
    fun setRunning(running: Boolean) = runJs(if (running) "Cubi.resume()" else "Cubi.pause()")

    private fun runJs(js: String) {
        if (isReady) webView.evaluateJavascript(js, null) else pendingJs += js
    }

    /** À appeler depuis onResume / onPause de l'Activity ou du Fragment hôte (économise la batterie). */
    fun resume() = webView.onResume()
    fun pause() = webView.onPause()

    /** À appeler quand la vue est détruite définitivement. */
    fun destroy() {
        webView.removeJavascriptInterface("CubiBridge")
        webView.stopLoading()
        webView.loadUrl("about:blank")
        removeView(webView)
        webView.destroy()
    }

    private inner class Bridge {
        @JavascriptInterface
        fun onReady() = mainHandler.post {
            isReady = true
            pendingJs.forEach { webView.evaluateJavascript(it, null) }
            pendingJs.clear()
            onReady?.invoke()
        }

        @JavascriptInterface
        fun onPoke() = mainHandler.post { onPoke?.invoke() }
    }

    companion object {
        /** Ajouter "?ui=1" pour afficher les boutons de démo (utile pour tester). */
        const val ASSET_URL = "file:///android_asset/cubi/index.html"
    }
}
