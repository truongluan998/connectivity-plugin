package com.example.mock_project.connectivity

import android.content.BroadcastReceiver
import android.content.Context
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.net.ConnectivityManager.CONNECTIVITY_ACTION
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result


class ConnectivityPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {
    private var applicationContext: Context? = null
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var connectivityManager: ConnectivityManager? = null
    private var connectivityStateChangeReceiver: BroadcastReceiver? = null

    private var networkCallback: ConnectivityManager.NetworkCallback? = null
    private val mainHandler: Handler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        this.applicationContext = binding.applicationContext
        this.connectivityManager =
            applicationContext!!.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        methodChannel = MethodChannel(binding.binaryMessenger, "chat_gpt/connectivity")
        eventChannel = EventChannel(binding.binaryMessenger, "chat_gpt/connectivity/event")
        eventChannel!!.setStreamHandler(this)
        methodChannel!!.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = null
        connectivityManager = null
        methodChannel!!.setMethodCallHandler(null)
        methodChannel = null
        eventChannel!!.setStreamHandler(null)
        eventChannel = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "checkConnectivity") {
            result.success(getNetworkType())
        } else {
            result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            networkCallback = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    sendEvent(events)
                }

                override fun onLost(network: Network) {
                    sendEvent(CONNECTIVITY_NONE, events)
                }
            }
            connectivityManager!!.registerDefaultNetworkCallback(networkCallback as ConnectivityManager.NetworkCallback)
        } else {
            applicationContext!!.registerReceiver(
                connectivityStateChangeReceiver,
                IntentFilter(CONNECTIVITY_ACTION)
            )
        }
    }

    override fun onCancel(arguments: Any?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            if (networkCallback != null) {
                connectivityManager!!.unregisterNetworkCallback(networkCallback!!)
                networkCallback = null
            }
        } else {
            try {
                applicationContext!!.unregisterReceiver(connectivityStateChangeReceiver)
                connectivityStateChangeReceiver = null
            } catch (_: Exception) {

            }
        }
    }

    private fun getNetworkType(): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val network: Network = connectivityManager?.activeNetwork!!
            val capabilities: NetworkCapabilities =
                connectivityManager?.getNetworkCapabilities(network)
                    ?: return CONNECTIVITY_NONE
            if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                return CONNECTIVITY_WIFI
            }
            if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)) {
                return CONNECTIVITY_ETHERNET
            }
            if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
                return CONNECTIVITY_MOBILE
            }
            if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_BLUETOOTH)) {
                return CONNECTIVITY_BLUETOOTH
            }
        }
        return CONNECTIVITY_NONE
    }

    private fun sendEvent(events: EventChannel.EventSink?) {
        val runnable = Runnable { events!!.success(getNetworkType()) }
        mainHandler.post(runnable)
    }

    private fun sendEvent(networkType: String, events: EventChannel.EventSink?) {
        val runnable = Runnable { events!!.success(networkType) }
        mainHandler.post(runnable)
    }

    companion object {
        const val CONNECTIVITY_NONE = "none"
        const val CONNECTIVITY_WIFI = "wifi"
        const val CONNECTIVITY_MOBILE = "mobile"
        const val CONNECTIVITY_ETHERNET = "ethernet"
        const val CONNECTIVITY_BLUETOOTH = "bluetooth"
    }
}
