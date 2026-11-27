# Avatar Cubito (WebView) : garder les méthodes appelées depuis JavaScript.
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
