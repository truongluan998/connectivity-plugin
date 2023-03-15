import 'package:connectivity/src/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'connectivity_platform_interface.dart';

/// An implementation of [ConnectivityPlatform] that uses method channels.
class MethodChannelConnectivity extends ConnectivityPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('chat_gpt/connectivity');

  /// The event channel used to receive ConnectivityResult changes from the native platform.
  @visibleForTesting
  EventChannel eventChannel =
  const EventChannel('chat_gpt/connectivity/event');

  Stream<ConnectivityResult>? _onConnectivityChanged;

  @override
  Stream<ConnectivityResult> onConnectivityChanged() {
    _onConnectivityChanged ??= eventChannel
        .receiveBroadcastStream()
        .map((dynamic result) => result.toString())
        .map(parseConnectivityResult);
    return _onConnectivityChanged!;
  }

  @override
  Future<ConnectivityResult> checkConnectivity() {
    return methodChannel
        .invokeMethod<String>('checkConnectivity')
        .then((value) => parseConnectivityResult(value ?? ''));
  }
}
