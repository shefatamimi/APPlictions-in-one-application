/// # Meter-reading module entry
///
/// Thin adapter between the platform and the module: it resolves the module's
/// dependencies from the service locator and hands the live session to the
/// first screen. The registry knows nothing about the module's internals.
library;

import 'package:flutter/material.dart';

import '../../injection_container.dart';
import '../../platform/domain/entities/platform_session.dart';
import 'data/coordinates_api.dart';
import 'presentation/coordinate_capture_page.dart';

/// Builds the entry screen of the meter-reading application.
Widget buildMeterReadingModule(BuildContext context, PlatformSession session) {
  return CoordinateCapturePage(
    api: sl<CoordinatesApi>(),
    session: session,
  );
}
