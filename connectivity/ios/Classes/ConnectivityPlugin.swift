import Flutter
import UIKit
import Foundation
import Reachability
import Network


public enum ConnectType {
  case none
  case wiredEthernet
  case wifi
  case cellular
  case other
}

public class ConnectivityPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private let connectProvider: ConnectProvider
  private var eventSink: FlutterEventSink?
  init(connectProvider: ConnectProvider) {
    self.connectProvider = connectProvider
    super.init()
    self.connectProvider.connectUpdateHandler = connectUpdateHandler
  }
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "chat_gpt/connectivity",
      binaryMessenger: registrar.messenger())

    let streamChannel = FlutterEventChannel(
      name: "chat_gpt/connectivity/event",
      binaryMessenger: registrar.messenger())

    let connectProvider: ConnectProvider
    if #available(iOS 12, *) {
      connectProvider = PathMonitorConnectProvider()
    } else {
      connectProvider = ReachabilityConnectProvider()
    }

    let instance = ConnectivityPlugin(connectProvider: connectProvider)
    streamChannel.setStreamHandler(instance)

    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "checkConnectivity":
      result(statusFrom(connectType: connectProvider.currentConnectType))
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  private func statusFrom(connectType: ConnectType) -> String {
    switch connectType {
    case .wifi:
      return "wifi"
    case .cellular:
      return "mobile"
    case .wiredEthernet:
      return "ethernet"
    case .other:
        return "other"
    case .none:
      return "none"
    }
  }
  public func onListen(
    withArguments _: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    connectProvider.start()
    connectUpdateHandler(connectType: connectProvider.currentConnectType)
    return nil
  }

  private func connectUpdateHandler(connectType: ConnectType) {
    DispatchQueue.main.async {
      self.eventSink?(self.statusFrom(connectType: connectType))
    }
  }

  public func onCancel(withArguments _: Any?) -> FlutterError? {
    connectProvider.stop()
    eventSink = nil
    return nil
  }
}

public protocol ConnectProvider: NSObjectProtocol {
  typealias ConnectUpdateHandler = (ConnectType) -> Void

  var currentConnectType: ConnectType { get }

  var connectUpdateHandler: ConnectUpdateHandler? { get set }

  func start()

  func stop()
}

@available(iOS 12, *)
public class PathMonitorConnectProvider: NSObject, ConnectProvider {

  private let queue = DispatchQueue.global(qos: .background)

  private var _pathMonitor: NWPathMonitor?

  public var currentConnectType: ConnectType {
    let path = ensurePathMonitor().currentPath
    // .satisfied means that the network is available
    if path.status == .satisfied {
      if path.usesInterfaceType(.wifi) {
        return .wifi
      } else if path.usesInterfaceType(.cellular) {
        return .cellular
      } else if path.usesInterfaceType(.wiredEthernet) {
        // .wiredEthernet is available in simulator
        // but for consistency it is probably correct to report .wifi
        return .wifi
      } else if path.usesInterfaceType(.other) {
        return .other
      }
    }
    return .none
  }

  public var connectUpdateHandler: ConnectUpdateHandler?

  override init() {
    super.init()
    _ = ensurePathMonitor()
  }

  public func start() {
    _ = ensurePathMonitor()
  }

  public func stop() {
    _pathMonitor?.cancel()
    _pathMonitor = nil
  }

  @discardableResult
  private func ensurePathMonitor() -> NWPathMonitor {
    if (_pathMonitor == nil) {
      let pathMonitor = NWPathMonitor()
      pathMonitor.start(queue: queue)
      pathMonitor.pathUpdateHandler = pathUpdateHandler
      _pathMonitor = pathMonitor
    }
    return _pathMonitor!
  }

  private func pathUpdateHandler(path: NWPath) {
    connectUpdateHandler?(currentConnectType)
  }
}


public class ReachabilityConnectProvider: NSObject, ConnectProvider {
  private var _reachability: Reachability?

  public var currentConnectType: ConnectType {
    let reachability = ensureReachability()
    switch reachability.connection {
    case .wifi:
      return .wifi
    case .cellular:
      return .cellular
    default:
      return .none
    }
  }

  public var connectUpdateHandler: ConnectUpdateHandler?

  override init() {
    super.init()
    _ = ensureReachability()
  }

  public func start() {
    let reachability = ensureReachability()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(reachabilityChanged),
      name: .reachabilityChanged,
      object: reachability)

    try? reachability.startNotifier()
  }

  public func stop() {
    NotificationCenter.default.removeObserver(
      self,
      name: .reachabilityChanged,
      object: _reachability)

    _reachability?.stopNotifier()
    _reachability = nil
  }

  private func ensureReachability() -> Reachability {
    if (_reachability == nil) {
      let reachability = try? Reachability()
      _reachability = reachability
    }
    return _reachability!
  }

  @objc private func reachabilityChanged(notification: NSNotification) {
    connectUpdateHandler?(currentConnectType)
  }
}