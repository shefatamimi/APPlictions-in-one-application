/// # AppColors
///
/// Single source of truth for every colour used by the platform shell.
///
/// The palette is derived from the corporate blue **#00529C**. Business
/// modules may declare their own accent colour in [AppRegistry], but they
/// must pick it from [moduleAccents] so the dashboard keeps one visual
/// language no matter how many applications are added later.
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Brand ─────────────────────────────────────────────────────────────────

  /// Corporate blue — the seed colour of the Material 3 scheme.
  static const Color primary = Color(0xFF00529C);

  /// Darker brand blue, used for the top of gradients and pressed states.
  static const Color primaryDark = Color(0xFF003B70);

  /// Lighter brand blue, used for the bottom of gradients and highlights.
  static const Color primaryLight = Color(0xFF1B78C9);

  /// Very light brand wash for selected rows, chips and icon backplates.
  static const Color primarySurface = Color(0xFFE9F2FA);

  // ─── Neutrals ──────────────────────────────────────────────────────────────

  /// Page background behind cards.
  static const Color background = Color(0xFFF4F7FB);

  /// Card / sheet background.
  static const Color surface = Color(0xFFFFFFFF);

  /// Hairline borders around cards and inputs.
  static const Color outline = Color(0xFFE3E9F0);

  /// Primary text colour.
  static const Color textPrimary = Color(0xFF0F172A);

  /// Secondary text colour (labels, captions).
  static const Color textSecondary = Color(0xFF64748B);

  /// Tertiary text colour (hints, disabled).
  static const Color textTertiary = Color(0xFF94A3B8);

  // ─── Semantic ──────────────────────────────────────────────────────────────

  static const Color success = Color(0xFF15803D);
  static const Color successSurface = Color(0xFFE7F6EC);
  static const Color warning = Color(0xFFB45309);
  static const Color danger = Color(0xFFC2354A);
  static const Color dangerSurface = Color(0xFFFDECEF);

  // ─── Module accents ────────────────────────────────────────────────────────

  /// Approved accent colours for application cards.
  ///
  /// Each entry is a `(start, end)` gradient pair for the card's large icon
  /// tile. New applications should reuse one of these instead of inventing a
  /// colour, which is what keeps an unbounded number of cards looking
  /// deliberate rather than random.
  static const Map<String, List<Color>> moduleAccents = {
    'blue': [Color(0xFF0B63B2), Color(0xFF1E8BD6)],
    'teal': [Color(0xFF00786F), Color(0xFF12A594)],
    'amber': [Color(0xFFB45309), Color(0xFFE8A33D)],
    'violet': [Color(0xFF5B3FBF), Color(0xFF8B6DE8)],
    'rose': [Color(0xFFB03050), Color(0xFFE0637F)],
    'green': [Color(0xFF15803D), Color(0xFF3FAF67)],
    'slate': [Color(0xFF334155), Color(0xFF64748B)],
    'cyan': [Color(0xFF0E6E88), Color(0xFF29A0BE)],
  };

  /// Returns the gradient registered under [name], falling back to `blue`
  /// so an unknown accent can never crash the dashboard.
  static List<Color> accent(String name) =>
      moduleAccents[name] ?? moduleAccents['blue']!;

  // ─── Gradients ─────────────────────────────────────────────────────────────

  /// Brand gradient used by the dashboard header and the splash screen.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryDark, primary, primaryLight],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );
}
