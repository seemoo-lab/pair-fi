package de.seemoo.pairfi

import android.util.Log
import de.seemoo.pairfi.channels.LocationServiceChannel
import de.seemoo.pairfi.channels.WifiP2pChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec

const val CHANNEL_GPWIFIP2P = "gp_wifip2p"
const val CHANNEL_LOCATION_SERVICE = "location_service"

class MainActivity : FlutterActivity() {
    private var wifiP2pChannel: WifiP2pChannel? = null
    private var locationServiceChannel: LocationServiceChannel? = null

    private val logTag = "MainActivity"

    override fun onDestroy(){
        super.onDestroy()
    }

    override fun onResume() {
        super.onResume()
        Log.d(logTag, "onResume")
    }

    override fun onPause() {
        super.onPause()
        Log.d(logTag, "onPause")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val taskQueue = flutterEngine.dartExecutor.binaryMessenger.makeBackgroundTaskQueue()

        // wifip2pimplementation audiocontrol implementation
        wifiP2pChannel = WifiP2pChannel(
            this,
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL_GPWIFIP2P,
                StandardMethodCodec.INSTANCE,
                taskQueue
            )
        )

        locationServiceChannel = LocationServiceChannel(
            this,
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL_LOCATION_SERVICE
            )
        )
    }
}
