import 'enums.dart';

ConnectivityResult parseConnectivityResult(String state) {
  switch (state) {
    case 'bluetooth':
      return ConnectivityResult.bluetooth;
    case 'wifi':
      return ConnectivityResult.wifi;
    case 'ethernet':
      return ConnectivityResult.ethernet;
    case 'mobile':
      return ConnectivityResult.mobile;
    case 'other':
      return ConnectivityResult.other;
    case 'none':
    default:
      return ConnectivityResult.none;
  }
}