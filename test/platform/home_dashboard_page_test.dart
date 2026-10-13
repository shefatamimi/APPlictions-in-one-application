/// Widget tests for the home dashboard: it must show the employee card and
/// exactly the applications the session grants — one card, several cards, or an
/// explicit "no access" screen.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
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
import 'package:ideco_platform/platform/presentation/widgets/app_module_card.dart';
import 'package:ideco_platform/platform/presentation/widgets/no_access_view.dart';

class StubRepository implements PlatformAuthRepository {
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

PlatformSession sessionWith(List<String> granted) => PlatformSession(
      employee: _employee,
      grantedModuleIds: granted,
      username: 'a.alsharif',
      password: 'secret',
    );

Future<void> pumpDashboard(
  WidgetTester tester,
  PlatformSession session, {
  Size size = const Size(400, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repository = StubRepository();

  await tester.pumpWidget(
    BlocProvider<PlatformAuthCubit>(
      create: (_) => PlatformAuthCubit(
        signIn: SignInUseCase(repository),
        signOut: SignOutUseCase(repository),
        restoreSession: RestoreSessionUseCase(repository),
      ),
      child: MaterialApp(
        theme: AppTheme.light,
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
        home: HomeDashboardPage(session: session),
      ),
    ),
  );

  // Let the staggered entrance animations settle.
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the employee card with number, department and workshop',
      (tester) async {
    await pumpDashboard(tester, sessionWith(['inspection', 'meter_reading']));

    expect(find.text('أسعد الشريف'), findsOneWidget);
    expect(find.textContaining('1187'), findsOneWidget);
    expect(find.text('قسم مكافحة سرقات التيار'), findsOneWidget);
    expect(find.text('ورشة إربد الشمالية'), findsOneWidget);
  });

  testWidgets('renders one card per authorised application', (tester) async {
    await pumpDashboard(tester, sessionWith(['inspection', 'meter_reading']));

    expect(find.byType(AppModuleCard), findsNTiles(2));
    expect(find.text('التفتيش الميداني'), findsOneWidget);
    expect(find.text('قراءة العدادات'), findsOneWidget);
  });

  testWidgets('a single entitlement shows only that application, as a hero',
      (tester) async {
    await pumpDashboard(tester, sessionWith(['meter_reading']));

    final cards = tester.widgetList<AppModuleCard>(find.byType(AppModuleCard));
    expect(cards.length, 1);
    expect(cards.first.isHero, isTrue);
    expect(cards.first.module.id, 'meter_reading');
    expect(find.text('التفتيش الميداني'), findsNothing);
  });

  testWidgets('exposes the notification and logout actions', (tester) async {
    await pumpDashboard(tester, sessionWith(['inspection']));

    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
  });

  testWidgets('logout asks for confirmation before ending the session',
      (tester) async {
    await pumpDashboard(tester, sessionWith(['inspection']));

    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الخروج'), findsWidgets);
    expect(find.text('إلغاء'), findsOneWidget);
  });

  testWidgets('no entitlement shows the explicit no-access screen',
      (tester) async {
    await pumpDashboard(tester, sessionWith(const []));

    expect(find.byType(NoAccessView), findsOneWidget);
    expect(find.byType(AppModuleCard), findsNothing);
  });

  testWidgets('the grid widens on a tablet viewport', (tester) async {
    // Two applications on a 1000 px wide screen must sit side by side rather
    // than stack, which is what the responsive column count guarantees.
    await pumpDashboard(
      tester,
      sessionWith(['inspection', 'meter_reading']),
      size: const Size(1000, 800),
    );

    final cards = find.byType(AppModuleCard);
    expect(cards, findsNTiles(2));

    final first = tester.getTopLeft(cards.at(0));
    final second = tester.getTopLeft(cards.at(1));
    expect(first.dy, second.dy);
  });
}

/// Readable alias for the common "expect N cards" assertion.
Matcher findsNTiles(int count) => findsNWidgets(count);
