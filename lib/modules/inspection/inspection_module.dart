/// # Inspection module entry
///
/// Adapts the platform session to the inspection feature's own
/// dashboard.
library;

import 'package:flutter/material.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../platform/domain/entities/platform_session.dart';

/// Builds the entry screen of the field-inspection application.
Widget buildInspectionModule(BuildContext context, PlatformSession session) {
  return HomePage(user: session.employee);
}
