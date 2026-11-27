package fr.cubemagique.cube_magique.avatar

import android.content.Context
import android.view.View
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.util.Collections
import java.util.WeakHashMap

/**
 * Pont entre Flutter et l'avatar 3D (CubiAvatarView).
 *
 * Chaque avatar affiché par Flutter a son propre canal « cubito/avatar_<id> » :
 *  - Flutter → Android : setExpression(nom), poke()
 *  - Android → Flutter : onReady(), onPoke()
 */
class CubiPlatformView(
    context: Context,
    messenger: BinaryMessenger,
    id: Int,
    args: Map<*, *>?,
) : PlatformView {
    private val avatar = CubiAvatarView(context)
    private val channel = MethodChannel(messenger, "cubito/avatar_$id")

    init {
        (args?.get("expression") as? String)?.let { name ->
            CubiExpression.entries.firstOrNull { it.jsName == name }?.let(avatar::setExpression)
        }
        avatar.onReady = { channel.invokeMethod("onReady", null) }
        avatar.onPoke = { channel.invokeMethod("onPoke", null) }
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setExpression" -> {
                    val e = CubiExpression.entries.firstOrNull { it.jsName == call.arguments }
                    if (e != null) avatar.setExpression(e)
                    result.success(null)
                }
                "pause" -> {
                    avatar.setRunning(false)
                    result.success(null)
                }
                "resume" -> {
                    avatar.setRunning(true)
                    result.success(null)
                }
                "poke" -> {
                    avatar.poke()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        live.add(this)
    }

    override fun getView(): View = avatar

    override fun dispose() {
        live.remove(this)
        channel.setMethodCallHandler(null)
        avatar.destroy()
    }

    fun resume() = avatar.resume()
    fun pause() = avatar.pause()

    companion object {
        const val VIEW_TYPE = "cubito/avatar"

        /** Avatars affichés, pour les mettre en pause quand l'appli passe en arrière-plan. */
        private val live: MutableSet<CubiPlatformView> =
            Collections.newSetFromMap(WeakHashMap())

        fun resumeAll() = live.toList().forEach { it.resume() }
        fun pauseAll() = live.toList().forEach { it.pause() }
    }
}

class CubiViewFactory(private val messenger: BinaryMessenger) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        CubiPlatformView(context, messenger, viewId, args as? Map<*, *>)
}
