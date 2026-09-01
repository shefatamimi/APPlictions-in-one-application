/// # PlatformAuthState
///
/// State of the one and only authentication flow of the platform.
///
/// ```
/// Checking ──► Unauthenticated ──► Authenticating ──► Authenticated
///     │              ▲                    │                │
///     └──────────────┴──── AuthFailed ◄───┘   signOut ──────┘
/// ```
library;

import 'package:equatable/equatable.dart';

import '../../domain/entities/platform_session.dart';

sealed class PlatformAuthState extends Equatable {
  const PlatformAuthState();

  @override
  List<Object?> get props => [];
}

/// Splash screen: looking for a cached session.
final class PlatformAuthChecking extends PlatformAuthState {
  const PlatformAuthChecking();
}

/// No session — the login screen is shown.
final class PlatformAuthUnauthenticated extends PlatformAuthState {
  /// Username of the last session, used to pre-fill the login field.
  final String lastUsername;

  const PlatformAuthUnauthenticated({this.lastUsername = ''});

  @override
  List<Object?> get props => [lastUsername];
}

/// Credentials submitted; the application probes are in flight.
final class PlatformAuthAuthenticating extends PlatformAuthState {
  const PlatformAuthAuthenticating();
}

/// Signed in. [session] carries the employee and the authorised applications.
final class PlatformAuthAuthenticated extends PlatformAuthState {
  final PlatformSession session;

  const PlatformAuthAuthenticated(this.session);

  @override
  List<Object?> get props => [session];
}

/// Login rejected or transport failed. The login screen shows [message] and
/// then returns to [PlatformAuthUnauthenticated].
final class PlatformAuthFailed extends PlatformAuthState {
  final String message;
  final String lastUsername;

  const PlatformAuthFailed(this.message, {this.lastUsername = ''});

  @override
  List<Object?> get props => [message, lastUsername];
}
