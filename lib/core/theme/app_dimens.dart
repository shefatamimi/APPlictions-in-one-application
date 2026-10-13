/// # AppDimens
///
/// Spacing, radius, elevation and motion tokens.
///
/// Every gap in the shell is a multiple of 4 so screens stay on a rhythm
/// when new cards or modules are appended.
library;

class AppDimens {
  AppDimens._();

  // ─── Spacing scale ─────────────────────────────────────────────────────────

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;

  // ─── Radius ────────────────────────────────────────────────────────────────

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 28;

  /// Radius of the rounded bottom corners of the dashboard header.
  static const double headerRadius = 32;

  // ─── Elevation ─────────────────────────────────────────────────────────────

  static const double cardElevation = 0;
  static const double cardHoverElevation = 6;

  // ─── Motion ────────────────────────────────────────────────────────────────

  /// Duration of card press / hover feedback.
  static const Duration fast = Duration(milliseconds: 150);

  /// Duration of the entrance animation of a single dashboard card.
  static const Duration medium = Duration(milliseconds: 420);

  /// Duration of page transitions.
  static const Duration slow = Duration(milliseconds: 600);

  /// Delay added per grid index so cards cascade instead of popping in at once.
  static const Duration staggerStep = Duration(milliseconds: 70);
}
