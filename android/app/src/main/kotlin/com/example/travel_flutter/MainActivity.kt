package com.example.travel_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
// REMOVE import io.flutter.plugins.google_mlkit_translation.GoogleMlKitTranslationPlugin

class MainActivity: FlutterActivity() {
    /* Remove this block
    override fun configureFlutterEngine() {
        super.configureFlutterEngine()
        // Register the plugin manually
        GoogleMlKitTranslationPlugin.registerWith(flutterEngine?.dartExecutor)
    }
    */
    // The engine provider is required for manual plugin registration
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        //GoogleMlKitTranslationPlugin.registerWith(flutterEngine.dartExecutor.binaryMessenger)
    }
}