package dev.posuniversal.printer

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import android.content.Intent
import android.content.IntentFilter
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Flutter plugin implementation for Android. Exposes methods over
 * `pos_universal_printer` channel to scan Bluetooth devices, connect
 * and disconnect, and write bytes to Bluetooth or TCP sockets. TCP
 * methods are included for completeness but the Dart side also
 * implements its own client.
 */
class PosUniversalPrinterPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private lateinit var bluetoothController: BluetoothController
    private val tcpClient = TcpSocketClient()
    private var receiverRegistered: Boolean = false
    private var events: EventChannel.EventSink? = null
    private val pluginScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        bluetoothController = BluetoothController(context)
        channel = MethodChannel(binding.binaryMessenger, "pos_universal_printer")
        channel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "pos_universal_printer/events")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "scanBluetooth" -> {
                pluginScope.launch {
                    try {
                        val devices = bluetoothController.scan()
                        result.success(devices)
                    } catch (e: Throwable) {
                        result.error("SCAN_ERROR", e.message, null)
                    }
                }
            }
            "connectBluetooth" -> {
                val address = call.argument<String>("address") ?: run {
                    result.error("BT_CONNECT", "Address missing", null)
                    return
                }
                pluginScope.launch {
                    val ok = bluetoothController.connect(address)
                    result.success(ok)
                }
            }
            "disconnectBluetooth" -> {
                val address = call.argument<String>("address") ?: run {
                    result.error("BT_DISCONNECT", "Address missing", null)
                    return
                }
                pluginScope.launch {
                    bluetoothController.disconnect(address)
                    result.success(true)
                }
            }
            "isBluetoothConnected" -> {
                val address = call.argument<String>("address") ?: run {
                    result.error("BT_IS_CONNECTED", "Address missing", null)
                    return
                }
                pluginScope.launch {
                    val ok = bluetoothController.isConnected(address)
                    result.success(ok)
                }
            }
            "writeBluetooth" -> {
                val address = call.argument<String>("address") ?: run {
                    result.error("BT_WRITE", "Address missing", null)
                    return
                }
                // Accept either a ByteArray (ideal) or a List<Int> coming from Dart MethodChannel.
                val raw = call.arguments as? Map<*, *>
                val anyBytes = raw?.get("bytes")
                val bytes: ByteArray = when (anyBytes) {
                    is ByteArray -> anyBytes
                    is List<*> -> {
                        try {
                            ByteArray(anyBytes.size) { idx ->
                                val v = anyBytes[idx]
                                if (v is Int) v.toByte() else 0
                            }
                        } catch (e: Exception) {
                            result.error("BT_WRITE", "Failed to cast bytes: ${e.message}", null)
                            return
                        }
                    }
                    else -> {
                        result.error("BT_WRITE", "Bytes missing or invalid type (${anyBytes?.javaClass})", null)
                        return
                    }
                }
                pluginScope.launch {
                    val ok = bluetoothController.write(address, bytes)
                    result.success(ok)
                }
            }
            "listConnectedBluetooth" -> {
                // listConnected() only inspects our map; safe to call directly
                result.success(bluetoothController.listConnected())
            }
            "disconnectAllBluetooth" -> {
                pluginScope.launch {
                    bluetoothController.disconnectAll()
                    result.success(true)
                }
            }
            // TCP support: connect, write, disconnect
            "connectTcp" -> {
                val host = call.argument<String>("host") ?: run {
                    result.error("TCP_CONNECT", "Host missing", null)
                    return
                }
                val port = call.argument<Int>("port") ?: 9100
                pluginScope.launch {
                    val ok = withContext(Dispatchers.IO) { tcpClient.connect(host, port) }
                    result.success(ok)
                }
            }
            "writeTcp" -> {
                val host = call.argument<String>("host") ?: run {
                    result.error("TCP_WRITE", "Host missing", null)
                    return
                }
                val port = call.argument<Int>("port") ?: 9100
                val raw = call.arguments as? Map<*, *>
                val anyBytes = raw?.get("bytes")
                val bytes: ByteArray = when (anyBytes) {
                    is ByteArray -> anyBytes
                    is List<*> -> {
                        try {
                            ByteArray(anyBytes.size) { idx ->
                                val v = anyBytes[idx]
                                if (v is Int) v.toByte() else 0
                            }
                        } catch (e: Exception) {
                            result.error("TCP_WRITE", "Failed to cast bytes: ${e.message}", null)
                            return
                        }
                    }
                    else -> {
                        result.error("TCP_WRITE", "Bytes missing or invalid type (${anyBytes?.javaClass})", null)
                        return
                    }
                }
                pluginScope.launch {
                    val ok = withContext(Dispatchers.IO) { tcpClient.write(host, port, bytes) }
                    result.success(ok)
                }
            }
            "disconnectTcp" -> {
                val host = call.argument<String>("host") ?: run {
                    result.error("TCP_DISCONNECT", "Host missing", null)
                    return
                }
                val port = call.argument<Int>("port") ?: 9100
                pluginScope.launch {
                    withContext(Dispatchers.IO) { tcpClient.disconnect(host, port) }
                    result.success(true)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        if (receiverRegistered) {
            try {
                context.unregisterReceiver(aclReceiver)
            } catch (e: Exception) {
                Log.w("PosPrinterPlugin", "Receiver unregister failed", e)
            }
            receiverRegistered = false
        }
        pluginScope.cancel()
    }

    // EventChannel implementation for Bluetooth ACL connection state changes
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.events = events
        if (!receiverRegistered) {
            val filter = IntentFilter().apply {
                addAction(BluetoothDevice.ACTION_ACL_CONNECTED)
                addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED)
                addAction(BluetoothDevice.ACTION_ACL_DISCONNECT_REQUESTED)
            }
            context.registerReceiver(aclReceiver, filter)
            receiverRegistered = true
        }
    }

    override fun onCancel(arguments: Any?) {
        this.events = null
        if (receiverRegistered) {
            try {
                context.unregisterReceiver(aclReceiver)
            } catch (e: Exception) {
                Log.w("PosPrinterPlugin", "Receiver unregister failed", e)
            }
            receiverRegistered = false
        }
    }

    private val aclReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.action ?: return
            val device: BluetoothDevice? = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
            val address = device?.address
            when (action) {
                BluetoothDevice.ACTION_ACL_CONNECTED -> {
                    events?.success(mapOf("type" to "bluetooth", "event" to "connected", "address" to address))
                }
                BluetoothDevice.ACTION_ACL_DISCONNECT_REQUESTED -> {
                    events?.success(mapOf("type" to "bluetooth", "event" to "disconnecting", "address" to address))
                }
                BluetoothDevice.ACTION_ACL_DISCONNECTED -> {
                    events?.success(mapOf("type" to "bluetooth", "event" to "disconnected", "address" to address))
                }
            }
        }
    }
}