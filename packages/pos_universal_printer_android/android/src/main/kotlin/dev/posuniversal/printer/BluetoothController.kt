package dev.posuniversal.printer

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.util.Log
import java.io.IOException
import java.util.UUID

/**
 * Manages Bluetooth Classic SPP connections. Supports scanning bonded
 * devices, connecting to a device by MAC address, sending data and
 * disconnecting. Uses the well‑known SPP UUID
 * 00001101-0000-1000-8000-00805F9B34FB【839086904073434†L139-L141】.
 */
class BluetoothController(private val context: Context) {
    private val adapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private val uuid: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val sockets: MutableMap<String, BluetoothSocket> = mutableMapOf()

    /**
     * Returns a list of bonded (paired) devices. Each device is
     * represented as a map with keys `name` and `address`.
     */
    fun scan(): List<Map<String, String?>> {
        val result = mutableListOf<Map<String, String?>>()
        val btAdapter = adapter ?: return result
        val bonded: Set<BluetoothDevice> = btAdapter.bondedDevices
        for (device in bonded) {
            val map = mapOf(
                "name" to device.name,
                "address" to device.address
            )
            result.add(map)
        }
        return result
    }

    /**
     * Attempts to connect to a device with the given MAC [address].
     * Returns true if the connection succeeds.
     */
    fun connect(address: String): Boolean {
        val btAdapter = adapter ?: return false
        val device = btAdapter.getRemoteDevice(address) ?: return false
        return try {
            val socket = device.createRfcommSocketToServiceRecord(uuid)
            btAdapter.cancelDiscovery()
            socket.connect()
            sockets[address] = socket
            true
        } catch (e: IOException) {
            Log.e("BluetoothController", "Error connecting to $address", e)
            false
        }
    }

    /**
     * Disconnects from the device with the given MAC [address].
     */
    fun disconnect(address: String) {
        try {
            sockets[address]?.close()
        } catch (e: IOException) {
            Log.e("BluetoothController", "Error closing socket for $address", e)
        }
        sockets.remove(address)
    }

    /**
     * Returns true if we have a socket tracked for [address] that is currently
     * reported connected. Note: for SPP this may still return true when the
     * device is out of range until the next IO failure. Use in combination
     * with ACL broadcast events for reliability.
     */
    fun isConnected(address: String): Boolean {
        val socket = sockets[address] ?: return false
        return try {
            socket.isConnected
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Sends [bytes] to the connected device identified by [address].
     * Returns true on success.
     */
    fun write(address: String, bytes: ByteArray): Boolean {
        val socket = sockets[address] ?: return false
        return try {
            val out = socket.outputStream
            out.write(bytes)
            out.flush()
            true
        } catch (e: IOException) {
            Log.e("BluetoothController", "Write failed for $address", e)
            false
        }
    }

    /** Returns a snapshot of currently tracked/connected addresses. */
    fun listConnected(): List<String> {
        return sockets.filter { it.value.isConnected }.map { it.key }
    }

    /** Disconnects all tracked sockets. */
    fun disconnectAll() {
        val keys = sockets.keys.toList()
        for (addr in keys) {
            disconnect(addr)
        }
    }
}