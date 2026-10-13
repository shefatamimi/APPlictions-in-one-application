/// # NetworkInfo
///
/// Abstraction over `connectivity_plus` for checking internet availability.
///
/// The original Android app used `NetTask` (an `AsyncTask` that resolved
/// `www.google.com` via `InetAddress`). Here we use `connectivity_plus`
/// which checks the active network connection type.
///
/// **Usage**:
/// ```dart
/// final bool online = await networkInfo.isConnected;
/// ```
library;

import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  /// Returns `true` when the device has an active network connection.
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  const NetworkInfoImpl(this.connectivity);

  /// ## isConnected
  ///
  /// **Description**: Checks whether the device currently has any active
  /// network interface (WiFi, mobile data, ethernet, VPN).
  ///
  /// **Returns**: `true` if at least one non-`none` connectivity result exists.
  ///
  /// **Throws**: Never — returns `false` on any exception.
  @override
  Future<bool> get isConnected async {
    try {
      final results = await connectivity.checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }
}
