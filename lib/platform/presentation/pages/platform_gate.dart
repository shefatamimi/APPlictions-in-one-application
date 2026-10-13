/// # PlatformGate
///
/// Realises the navigation flow of the platform:
///
/// ```
/// Splash → Login → (authenticate + permissions) → Home dashboard → Module
/// ```
///
/// The gate is declarative: it maps the authentication state to a screen, so a
/// logout from anywhere in any module returns to the login screen and a
/// restored session lands directly on the dashboard. Modules are pushed on top
/// of the dashboard, which is what keeps "back" meaning "back to the
/// application grid".
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_dimens.dart';
import '../cubit/platform_auth_cubit.dart';
import '../cubit/platform_auth_state.dart';
import 'home_dashboard_page.dart';
import 'login_page.dart';
import 'splash_page.dart';

class PlatformGate extends StatefulWidget {
  const PlatformGate({super.key});

  /// Minimum time the splash stays on screen, so a fast keychain read does not
  /// produce a jarring flash of the brand.
  static const Duration splashMinimumDuration = Duration(milliseconds: 1400);

  @override
  State<PlatformGate> createState() => _PlatformGateState();
}

class _PlatformGateState extends State<PlatformGate> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(PlatformGate.splashMinimumDuration);
    if (mounted) await context.read<PlatformAuthCubit>().bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlatformAuthCubit, PlatformAuthState>(
      builder: (context, state) {
        final child = switch (state) {
          PlatformAuthChecking() => const SplashPage(),
          PlatformAuthAuthenticated(:final session) => HomeDashboardPage(
              key: const ValueKey('dashboard'), session: session),
          PlatformAuthUnauthenticated(:final lastUsername) => LoginPage(
              key: const ValueKey('login'),
              initialUsername: lastUsername,
            ),
          PlatformAuthAuthenticating() ||
          PlatformAuthFailed() =>
            // The login screen renders its own busy / error affordances, so it
            // stays mounted across these two states.
            const LoginPage(key: ValueKey('login')),
        };

        return AnimatedSwitcher(
          duration: AppDimens.slow,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: child,
        );
      },
    );
  }
}
