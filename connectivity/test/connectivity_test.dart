import 'package:connectivity/src/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity/connectivity.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockConnectivityPlatform
    with MockPlatformInterfaceMixin
    implements ConnectivityPlatform {
  @override
  Future<ConnectivityResult> checkConnectivity() {
    // TODO: implement checkConnectivity
    throw UnimplementedError();
  }

  @override
  Stream<ConnectivityResult> onConnectivityChanged () {
    // TODO: implement onConnectivityChanged
    throw UnimplementedError();
  }
}

void main() {
  final ConnectivityPlatform initialPlatform = ConnectivityPlatform.instance;

  test('$MethodChannelConnectivity is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelConnectivity>());
  });

  test('getPlatformVersion', () async {
    ConnectivityImp connectivityPlugin = ConnectivityImp();
    MockConnectivityPlatform fakePlatform = MockConnectivityPlatform();
    ConnectivityPlatform.instance = fakePlatform;
  });
}
