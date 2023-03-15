import 'package:connectivity/src/enums.dart';

import 'connectivity_platform_interface.dart';

class ConnectivityImp {
  Stream<ConnectivityResult> onConnectivityChanged() => ConnectivityPlatform.instance.onConnectivityChanged();

  Future<ConnectivityResult> checkConnectivity() => ConnectivityPlatform.instance.checkConnectivity();
}
