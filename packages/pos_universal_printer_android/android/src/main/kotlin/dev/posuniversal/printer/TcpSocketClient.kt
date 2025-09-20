package dev.posuniversal.printer

import android.util.Log
import java.io.IOException
import java.net.InetSocketAddress
import java.net.Socket
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Simple TCP client for printers. Manages multiple sockets keyed by
 * host:port. Provides connect, write and disconnect operations. This
 * class is used by the Flutter plugin as a thin wrapper over Java
 * sockets. The Dart implementation also provides a TCP client; this
 * class is included to fulfil the federated plugin contract.
 */
class TcpSocketClient {
    private val sockets: MutableMap<String, Socket> = mutableMapOf()

    private fun key(host: String, port: Int) = "$host:$port"

    /** Connects to [host]:[port] and returns true on success. */
    suspend fun connect(host: String, port: Int): Boolean = withContext(Dispatchers.IO) {
        val k = key(host, port)
        if (sockets.containsKey(k)) return@withContext true
        return@withContext try {
            val socket = Socket()
            socket.connect(InetSocketAddress(host, port), 5000)
            sockets[k] = socket
            true
        } catch (e: IOException) {
            Log.e("TcpSocketClient", "Connect failed to $host:$port", e)
            false
        }
    }

    /** Writes [bytes] to the connected socket for [host]:[port]. */
    suspend fun write(host: String, port: Int, bytes: ByteArray): Boolean = withContext(Dispatchers.IO) {
        val k = key(host, port)
        val socket = sockets[k] ?: return@withContext false
        return@withContext try {
            val out = socket.getOutputStream()
            out.write(bytes)
            out.flush()
            true
        } catch (e: IOException) {
            Log.e("TcpSocketClient", "Write failed to $host:$port", e)
            false
        }
    }

    /** Disconnects from [host]:[port]. */
    suspend fun disconnect(host: String, port: Int) = withContext(Dispatchers.IO) {
        val k = key(host, port)
        try {
            sockets[k]?.close()
        } catch (e: IOException) {
            Log.e("TcpSocketClient", "Error closing $host:$port", e)
        }
        sockets.remove(k)
    }
}