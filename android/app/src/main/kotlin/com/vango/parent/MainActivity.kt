package com.vango.parent

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.vango.app/apikey"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getApiKey") {
                // Gets the auto-generated API key from google-services.json
                val resourceId = resources.getIdentifier("google_api_key", "string", packageName)
                if (resourceId != 0) {
                    val apiKey = getString(resourceId)
                    result.success(apiKey)
                } else {
                    result.error("UNAVAILABLE", "API Key not found in google-services.json.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}