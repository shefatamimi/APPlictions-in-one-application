/// # main.dart
///
/// Entry point of the **IDECO unified enterprise platform**.
///
/// The platform hosts several business applications behind one login, one
/// service endpoint and one database:
///
/// ```
/// Splash → Login → authenticate + resolve permissions
///        → Home dashboard (only the authorised applications)
///        → selected application
/// ```
///
/// This file owns three things only: the theme, the Arabic/RTL localisation and
/// the root gate. Applications are declared in `AppRegistry`, so shipping a new
/// one never touches `main.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/sync_page.dart';
import 'features/inquiry/presentation/pages/inquiry_page.dart';
import 'features/inspection_inquiry/presentation/pages/inspection_execution_page.dart';
import 'features/inspection_inquiry/presentation/pages/inspection_inquiry_page.dart';
import 'features/inspection_inquiry/presentation/pages/inspection_movement_page.dart';
import 'features/meter/presentation/meter_remove.dart';
import 'features/submission/presentation/pages/submission_page.dart';
import 'injection_container.dart';
import 'platform/presentation/cubit/platform_auth_cubit.dart';
import 'platform/presentation/pages/platform_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  setupDependencies();
  runApp(const IdecoPlatformApp());
}

class IdecoPlatformApp extends StatelessWidget {
  const IdecoPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PlatformAuthCubit>(
      // Singleton: one session shared by the shell and every module.
      create: (_) => sl<PlatformAuthCubit>(),
      child: MaterialApp(
        title: 'منصة تطبيقات كهرباء إربد',
        debugShowCheckedModeBanner: false,

        theme: AppTheme.light,
        themeMode: ThemeMode.light,

        // Arabic-first, right-to-left across the whole platform.
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),

        // Splash → login → dashboard, driven by the authentication state.
        home: const PlatformGate(),

        // Inner screens of the field-inspection application: that code base
        // navigates by name, so its routes stay registered here.
        routes: {
          '/inquiry': (_) => const InquiryPage(),
          '/inspection-inquiry': (_) => const InspectionInquiryPage(),
          '/inspection-execution': (_) => const InspectionExecutionScreen(),
          '/inspection-movement': (_) => const InspectionMovementPage(),
          '/submission': (_) => const SubmissionPage(),
          '/meter-remove': (_) => const MeterRemovalScreen(),
          '/sync': (_) => const SyncPage(),
        },
      ),
    );
  }
}
