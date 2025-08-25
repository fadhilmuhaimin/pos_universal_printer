import Foundation
import Network

/// Simple TCP client for iOS using Apple's Network framework. Supports
/// connecting to a host and port, sending data and disconnecting.
@available(iOS 12.0, *)
class TcpClient {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "pos.tcpClient")

    /// Connects to the remote [host] and [port]. Any existing connection
    /// is cancelled.
    func connect(host: String, port: UInt16) {
        disconnect()
        let endpointHost = NWEndpoint.Host(host)
        guard let endpointPort = NWEndpoint.Port(rawValue: port) else {
            return
        }
        connection = NWConnection(host: endpointHost, port: endpointPort, using: .tcp)
        connection?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                NSLog("TCP connection ready to \(host):\(port)")
            case .failed(let error):
                NSLog("TCP connection failed: \(error)")
            default:
                break
            }
        }
        connection?.start(queue: queue)
    }

    /// Sends [data] over the connection. Calls [completion] with a
    /// boolean indicating success.
    func send(data: Data, completion: ((Bool) -> Void)? = nil) {
        guard let conn = connection else {
            completion?(false)
            return
        }
        conn.send(content: data, completion: .contentProcessed { error in
            if let _ = error {
                completion?(false)
            } else {
                completion?(true)
            }
        })
    }

    /// Cancels the current connection.
    func disconnect() {
        connection?.cancel()
        connection = nil
    }
}