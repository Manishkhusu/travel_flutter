package com.example.myapp // Update to match your package name

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    // The engine provider is required for manual plugin registration
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // No need for manual plugin registration for GoogleMlKitTranslationPlugin
    }
}
