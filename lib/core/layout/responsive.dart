/// # Responsive
///
/// Breakpoint helpers shared by the shell and the modules.
///
/// The dashboard never hard-codes a column count: it asks
/// [Responsive.appGridColumns] for one, so the same code renders a phone in
/// portrait, a phone in landscape, a rugged 8" field tablet and the desktop
/// build of the app without edits.
library;

import 'package:flutter/widgets.dart';

/// Device size buckets, in logical pixels of the shortest visible width.
enum ScreenSize {
  /// < 600 — phones in portrait.
  compact,

  /// 600–904 — large phones in landscape, small tablets.
  medium,

  /// 905–1239 — tablets, small desktop windows.
  expanded,

  /// >= 1240 — desktop.
  large,
}

class Responsive {
  Responsive._();

  static const double _mediumBreakpoint = 600;
  static const double _expandedBreakpoint = 905;
  static const double _largeBreakpoint = 1240;

  /// Classifies [width] into a [ScreenSize] bucket.
  static ScreenSize sizeOf(double width) {
    if (width >= _largeBreakpoint) return ScreenSize.large;
    if (width >= _expandedBreakpoint) return ScreenSize.expanded;
    if (width >= _mediumBreakpoint) return ScreenSize.medium;
    return ScreenSize.compact;
  }

  /// Classifies the current [BuildContext] into a [ScreenSize] bucket.
  static ScreenSize of(BuildContext context) =>
      sizeOf(MediaQuery.sizeOf(context).width);

  /// ## appTileMaxWidth
  ///
  /// **Description**: Upper bound on the width of one application tile. The
  /// grid derives its column count from this, so the cards keep a sane size
  /// whether the catalogue holds two applications or twenty, on a phone or on a
  /// desktop window.
  ///
  /// **Returns**: a width in logical pixels.
  static double appTileMaxWidth(BuildContext context) => switch (of(context)) {
        ScreenSize.compact => 220,
        ScreenSize.medium => 240,
        ScreenSize.expanded => 250,
        ScreenSize.large => 260,
      };

  /// Fixed height of an application tile, so every card is the same size no
  /// matter how much room the row has.
  static double appTileHeight(BuildContext context) =>
      of(context) == ScreenSize.compact ? 200 : 210;

  /// Height of the wide single-application "hero" card.
  static double appHeroHeight(BuildContext context) =>
      of(context) == ScreenSize.compact ? 128 : 136;

  /// Width cap of the hero card — a single application should not span a whole
  /// desktop window.
  static double appHeroMaxWidth(BuildContext context) =>
      isWide(context) ? 620 : double.infinity;

  /// Maximum content width. Keeps text and cards readable when the app runs
  /// maximised on a desktop or a landscape tablet.
  static double maxContentWidth(BuildContext context) => switch (of(context)) {
        ScreenSize.compact => double.infinity,
        ScreenSize.medium => 760,
        ScreenSize.expanded => 1040,
        ScreenSize.large => 1240,
      };

  /// Horizontal page padding that grows with the viewport.
  static double pagePadding(BuildContext context) => switch (of(context)) {
        ScreenSize.compact => 16,
        ScreenSize.medium => 24,
        ScreenSize.expanded => 32,
        ScreenSize.large => 40,
      };

  /// `true` when the viewport is at least tablet-wide.
  static bool isWide(BuildContext context) => of(context) != ScreenSize.compact;
}

/// Centres its [child] and caps it at [Responsive.maxContentWidth].
class ContentBounds extends StatelessWidget {
  const ContentBounds({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.maxContentWidth(context),
        ),
        child: child,
      ),
    );
  }
}
