package dev.posuniversal.printer

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Flutter plugin implementation for Android. Exposes methods over
 * `pos_universal_printer` channel to scan Bluetooth devices, connect
 * and disconnect, and write bytes to Bluetooth or TCP sockets. TCP
 * methods are included for completeness but the Dart side also
 * implements its own client.
 */
class PosUniversalPrinterPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var bluetoothController: BluetoothController
    private val tcpClient = TcpSocketClient()

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        bluetoothController = BluetoothController(context)
        channel = MethodChannel(binding.binaryMessenger, "pos_universal_printer")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "scanBluetooth" -> {
                val devices = bluetoothController.scan()
                result.success(devices)
            }
            "connectBluetooth" -> {
                val address = call.argument<String>("address") ?: run {
                    result.error("BT_CONNECT", "Address missing", null)
                    return
                }
                val ok = bluetoothController.connect(address)
                result.success(ok)
            }
            "disconnectBluetooth" -> {
                val address = call.argument<String>("address") ?: run {
                    result.error("BT_DISCONNECT", "Address missing", null)
                    return
                }
                bluetoothController.disconnect(address)
                result.success(true)
            }
            "writeBluetooth" -> {
                val address = call.argument<String>("address") ?: run {
                    result.error("BT_WRITE", "Address missing", null)
                    return
                }
                val bytes = call.argument<ByteArray>("bytes") ?: run {
                    result.error("BT_WRITE", "Bytes missing", null)
                    return
                }
                val ok = bluetoothController.write(address, bytes)
                result.success(ok)
            }
            // TCP support: connect, write, disconnect
            "connectTcp" -> {
                val host = call.argument<String>("host") ?: run {
                    result.error("TCP_CONNECT", "Host missing", null)
                    return
                }
                val port = call.argument<Int>("port") ?: 9100
                val ok = tcpClient.connect(host, port)
                result.success(ok)
            }
            "writeTcp" -> {
                val host = call.argument<String>("host") ?: run {
                    result.error("TCP_WRITE", "Host missing", null)
                    return
                }
                val port = call.argument<Int>("port") ?: 9100
                val bytes = call.argument<ByteArray>("bytes") ?: run {
                    result.error("TCP_WRITE", "Bytes missing", null)
                    return
                }
                val ok = tcpClient.write(host, port, bytes)
                result.success(ok)
            }
            "disconnectTcp" -> {
                val host = call.argument<String>("host") ?: run {
                    result.error("TCP_DISCONNECT", "Host missing", null)
                    return
                }
                val port = call.argument<Int>("port") ?: 9100
                tcpClient.disconnect(host, port)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}