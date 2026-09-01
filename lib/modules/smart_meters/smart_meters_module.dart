/// # Smart-meters module entry
///
/// Adapter between the Super App and the Irbid Electricity Smart Meters app.
library;

import 'package:flutter/material.dart';
import '../../platform/domain/entities/platform_session.dart';
import 'package:ideco_platform/features/meter/screens/home_screen.dart';

/// دالة بناء الموديول التي يستدعيها التطبيق الرئيسي عند الضغط على الكارد.
Widget buildSmartMetersModule(BuildContext context, PlatformSession session) {
  return const HomeScreen();
}
