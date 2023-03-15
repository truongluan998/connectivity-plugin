import 'package:connectivity/src/enums.dart';
export 'src/enums.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'connectivity_method_channel.dart';

abstract class ConnectivityPlatform extends PlatformInterface {
  /// Constructs a ConnectivityPlatform.
  ConnectivityPlatform() : super(token: _token);

  static final Object _token = Object();

  static ConnectivityPlatform _instance = MethodChannelConnectivity();

  /// The default instance of [ConnectivityPlatform] to use.
  ///
  /// Defaults to [MethodChannelConnectivity].
  static ConnectivityPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ConnectivityPlatform] when
  /// they register themselves.
  static set instance(ConnectivityPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Checks the connection status of the device.
  Future<ConnectivityResult> checkConnectivity() {
    throw UnimplementedError('checkConnectivity() has not been implemented.');
  }

  /// Returns a Stream of ConnectivityResults changes.
  Stream<ConnectivityResult> onConnectivityChanged() {
    throw UnimplementedError(
        'get onConnectivityChanged has not been implemented.');
  }
}
