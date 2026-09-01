/// # AppModule
///
/// Declarative description of one business application hosted by the platform.
///
/// This is the **only** contract a new application has to satisfy. The
/// dashboard, the permission check and the session plumbing are all driven by
/// the fields below, which is why adding "Disconnect / Reconnect", "Complaints",
/// "Maintenance", "GIS" or "Inventory" later means appending one entry to
/// `AppRegistry.modules` — no change to any widget.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'platform_session.dart';

/// Builds the entry screen of a module. It receives the live session so the
/// module never has to read credentials or re-authenticate.
typedef ModuleScreenBuilder = Widget Function(
  BuildContext context,
  PlatformSession session,
);

class AppModule extends Equatable {
  /// Stable identifier, persisted in the cached session
  /// (e.g. `inspection`, `meter_reading`). Never localise this.
  final String id;

  /// Application id the legacy service uses to authorise this module —
  /// the `b.app_id = N` filter of `GetAppLoginUser`.
  ///
  /// * 20 → field inspection
  /// * 49 → meter reading / coordinate capture
  ///
  /// The server-side permission table is the single source of truth: if the
  /// employee has no row for this id, the login probe returns nothing and the
  /// card is not rendered.
  final int serverAppId;

  /// `DataType` prefix of the login query for this application. The two legacy
  /// apps send different values (14 and 1) and both are preserved verbatim so
  /// no backend change is required.
  final int loginDataType;

  /// Card title (Arabic).
  final String title;

  /// One-line card description (Arabic).
  final String description;

  /// Large card icon.
  final IconData icon;

  /// Key into `AppColors.moduleAccents` for the icon gradient.
  final String accent;

  /// Named route the shell registers for this module.
  final String route;

  /// Builds the module's entry screen.
  final ModuleScreenBuilder builder;

  /// When `false` the module is skipped entirely: no login probe, no card.
  /// Use it to ship a module that the backend does not expose yet.
  final bool enabled;

  /// Optional badge shown on the card, e.g. `تجريبي` for a pilot rollout.
  final String? badge;

  const AppModule({
    required this.id,
    required this.serverAppId,
    required this.loginDataType,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.route,
    required this.builder,
    this.enabled = true,
    this.badge,
  });

  @override
  List<Object?> get props => [id, serverAppId, loginDataType, route];
}
