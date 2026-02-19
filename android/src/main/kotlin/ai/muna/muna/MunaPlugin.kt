package ai.muna.muna

import io.flutter.embedding.engine.plugins.FlutterPlugin

class MunaPlugin : FlutterPlugin {
    companion object {
        init {
            System.loadLibrary("Function")
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
}
