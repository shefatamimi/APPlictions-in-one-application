/// # PlatformSession
///
/// The result of the single sign-on: who the employee is, and which
/// applications the server authorised them to open.
///
/// Everything downstream — the dashboard grid, the module screens, the legacy
/// SOAP payloads — reads from this object, so a module can never see a
/// different identity than the one the shell authenticated.
library;

import 'package:equatable/equatable.dart';

import 'employee.dart';

class PlatformSession extends Equatable {
  /// The signed-in employee.
  final Employee employee;

  /// Ids of the [AppModule]s the server granted, in registry order.
  final List<String> grantedModuleIds;

  /// Login name exactly as typed. Required by legacy SOAP operations that
  /// stamp `entry_user` with it.
  final String username;

  /// Password kept for the lifetime of the session only because two legacy
  /// operations re-send the credentials; it is stored in the platform keychain,
  /// never in plain preferences.
  final String password;

  /// `true` when the session was restored from cache while offline, so screens
  /// can warn the user that lists may be stale.
  final bool isOffline;

  const PlatformSession({
    required this.employee,
    required this.grantedModuleIds,
    required this.username,
    required this.password,
    this.isOffline = false,
  });

  /// Whether the employee may open [moduleId].
  bool canAccess(String moduleId) => grantedModuleIds.contains(moduleId);

  /// Whether exactly one application is available — the dashboard renders a
  /// single hero card in that case.
  bool get hasSingleApp => grantedModuleIds.length == 1;

  /// Whether the employee has no application at all.
  bool get hasNoApps => grantedModuleIds.isEmpty;

  PlatformSession copyWith({
    Employee? employee,
    List<String>? grantedModuleIds,
    String? username,
    String? password,
    bool? isOffline,
  }) {
    return PlatformSession(
      employee: employee ?? this.employee,
      grantedModuleIds: grantedModuleIds ?? this.grantedModuleIds,
      username: username ?? this.username,
      password: password ?? this.password,
      isOffline: isOffline ?? this.isOffline,
    );
  }

  @override
  List<Object?> get props => [
        employee,
        grantedModuleIds,
        username,
        isOffline,
      ];
}
