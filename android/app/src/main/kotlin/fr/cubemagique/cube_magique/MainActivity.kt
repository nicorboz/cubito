package fr.cubemagique.cube_magique

import fr.cubemagique.cube_magique.avatar.CubiPlatformView
import fr.cubemagique.cube_magique.avatar.CubiViewFactory
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // L'écran ne se met jamais en veille tant que l'appli est ouverte
        // (scan à la caméra, leçons que l'on regarde sans toucher l'écran).
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Avatar 3D Cubito (WebView hors ligne), affiché par Flutter.
        flutterEngine.platformViewsController.registry.registerViewFactory(
            CubiPlatformView.VIEW_TYPE,
            CubiViewFactory(flutterEngine.dartExecutor.binaryMessenger),
        )
    }

    override fun onResume() {
        super.onResume()
        CubiPlatformView.resumeAll()
    }

    override fun onPause() {
        CubiPlatformView.pauseAll()
        super.onPause()
    }
}
