/// Golden renders of the platform screens with the real bundled Arabic font.
///
/// These exist to catch visual regressions (spacing, RTL layout, overflow) that
/// behavioural tests cannot see. Refresh them with:
///
/// ```
/// flutter test --update-goldens test/golden
/// ```
library;

import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ideco_platform/core/errors/failures.dart';
import 'package:ideco_platform/core/theme/app_theme.dart';
import 'package:ideco_platform/platform/domain/entities/app_module.dart';
import 'package:ideco_platform/platform/domain/entities/employee.dart';
import 'package:ideco_platform/platform/domain/entities/platform_session.dart';
import 'package:ideco_platform/platform/domain/repositories/platform_auth_repository.dart';
import 'package:ideco_platform/platform/domain/usecases/restore_session_usecase.dart';
import 'package:ideco_platform/platform/domain/usecases/sign_in_usecase.dart';
import 'package:ideco_platform/platform/domain/usecases/sign_out_usecase.dart';
import 'package:ideco_platform/platform/presentation/cubit/platform_auth_cubit.dart';
import 'package:ideco_platform/platform/presentation/pages/home_dashboard_page.dart';
import 'package:ideco_platform/features/home/presentation/pages/home_page.dart';
import 'package:ideco_platform/modules/inspection/inspection_module.dart';
import 'package:ideco_platform/platform/presentation/pages/login_page.dart';

class GoldenRepository implements PlatformAuthRepository {
  @override
  Future<Either<Failure, PlatformSession>> signIn({
    required String username,
    required String password,
    required List<AppModule> modules,
  }) async =>
      const Left(AuthFailure());

  @override
  Future<Either<Failure, PlatformSession?>> restoreSession() async =>
      const Right(null);

  @override
  Future<Either<Failure, Unit>> signOut() async => const Right(unit);
}

const _employee = Employee(
  id: '4321',
  employeeNumber: '1187',
  username: 'a.alsharif',
  fullName: 'أسعد الشريف',
  department: 'قسم مكافحة سرقات التيار',
  workshopName: 'ورشة إربد الشمالية',
  workshopNumber: '7',
  oracleUser: 'IDECO_APP',
  systemMinor: '3',
);

/// Loads the app's bundled Arabic font so goldens show real glyph shaping
/// instead of the test placeholder font.
Future<void> loadAppFont() async {
  final bytes = File('assets/fonts/ad_font.ttf').readAsBytesSync();
  final loader = FontLoader('AdFont')
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

Widget wrap(Widget child) {
  final repository = GoldenRepository();
  return BlocProvider<PlatformAuthCubit>(
    create: (_) => PlatformAuthCubit(
      signIn: SignInUseCase(repository),
      signOut: SignOutUseCase(repository),
      restoreSession: RestoreSessionUseCase(repository),
    ),
    child: MaterialApp(
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, inner) => Directionality(
        textDirection: TextDirection.rtl,
        child: inner ?? const SizedBox.shrink(),
      ),
      home: child,
    ),
  );
}

Future<void> pumpAt(
  WidgetTester tester,
  Widget child, {
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(wrap(child));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFont);

  testWidgets('dashboard — phone, two applications', (tester) async {
    await pumpAt(
      tester,
      HomeDashboardPage(
        session: const PlatformSession(
          employee: _employee,
          grantedModuleIds: ['inspection', 'meter_reading'],
          username: 'a.alsharif',
          password: 'secret',
        ),
      ),
      size: const Size(400, 820),
    );

    await expectLater(
      find.byType(HomeDashboardPage),
      matchesGoldenFile('goldens/dashboard_phone_two_apps.png'),
    );
  });

  testWidgets('dashboard — phone, single application', (tester) async {
    await pumpAt(
      tester,
      HomeDashboardPage(
        session: const PlatformSession(
          employee: _employee,
          grantedModuleIds: ['meter_reading'],
          username: 'a.alsharif',
          password: 'secret',
        ),
      ),
      size: const Size(400, 820),
    );

    await expectLater(
      find.byType(HomeDashboardPage),
      matchesGoldenFile('goldens/dashboard_phone_single_app.png'),
    );
  });

  testWidgets('dashboard — tablet, offline session', (tester) async {
    await pumpAt(
      tester,
      HomeDashboardPage(
        session: const PlatformSession(
          employee: _employee,
          grantedModuleIds: ['inspection', 'meter_reading'],
          username: 'a.alsharif',
          password: 'secret',
          isOffline: true,
        ),
      ),
      size: const Size(1000, 760),
    );

    await expectLater(
      find.byType(HomeDashboardPage),
      matchesGoldenFile('goldens/dashboard_tablet.png'),
    );
  });

  testWidgets('login — phone', (tester) async {
    await pumpAt(tester, const LoginPage(), size: const Size(400, 820));

    await expectLater(
      find.byType(LoginPage),
      matchesGoldenFile('goldens/login_phone.png'),
    );
  });

  testWidgets('inspection module — hosted inside the platform', (tester) async {
    // The module inherits the platform theme and offers "back to applications"
    // instead of owning the logout.
    await pumpAt(
      tester,
      Builder(
        builder: (context) => buildInspectionModule(
          context,
          const PlatformSession(
            employee: _employee,
            grantedModuleIds: ['inspection', 'meter_reading'],
            username: 'a.alsharif',
            password: 'secret',
          ),
        ),
      ),
      size: const Size(400, 900),
    );

    await expectLater(
      find.byType(HomePage),
      matchesGoldenFile('goldens/inspection_module_phone.png'),
    );
  });
}
