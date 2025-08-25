import Flutter
import UIKit

/// iOS implementation of the pos_universal_printer plugin. Only TCP
/// connections are supported because iOS does not expose the
/// Bluetooth Serial Port Profile except via MFi devices【229364017025404†L45-L58】.
public class PosUniversalPrinterIosPlugin: NSObject, FlutterPlugin {
  private var tcpClients: [String: TcpClient] = [:]

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "pos_universal_printer", binaryMessenger: registrar.messenger())
    let instance = PosUniversalPrinterIosPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "scanBluetooth":
      // iOS does not support Bluetooth SPP scanning without MFi; return empty list
      result([])
    case "connectBluetooth":
      // Always fail
      result(false)
    case "disconnectBluetooth":
      result(nil)
    case "writeBluetooth":
      result(false)
    case "connectTcp":
      guard let args = call.arguments as? [String: Any],
            let host = args["host"] as? String,
            let port = args["port"] as? Int else {
        result(false)
        return
      }
      let key = "\(host):\(port)"
      let client: TcpClient
      if let existing = tcpClients[key] {
        client = existing
      } else {
        client = TcpClient()
        tcpClients[key] = client
      }
      client.connect(host: host, port: UInt16(port))
      result(true)
    case "writeTcp":
      guard let args = call.arguments as? [String: Any],
            let host = args["host"] as? String,
            let port = args["port"] as? Int,
            let bytes = args["bytes"] as? FlutterStandardTypedData else {
        result(false)
        return
      }
      let key = "\(host):\(port)"
      guard let client = tcpClients[key] else {
        result(false)
        return
      }
      client.send(data: Data(bytes.data)) { ok in
        result(ok)
      }
    case "disconnectTcp":
      guard let args = call.arguments as? [String: Any],
            let host = args["host"] as? String,
            let port = args["port"] as? Int else {
        result(nil)
        return
      }
      let key = "\(host):\(port)"
      if let client = tcpClients[key] {
        client.disconnect()
        tcpClients.removeValue(forKey: key)
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}