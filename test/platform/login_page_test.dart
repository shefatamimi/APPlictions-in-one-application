/// Widget tests for the platform's single login screen.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ideco_platform/core/errors/failures.dart';
import 'package:ideco_platform/core/theme/app_theme.dart';
import 'package:ideco_platform/platform/domain/entities/app_module.dart';
import 'package:ideco_platform/platform/domain/entities/platform_session.dart';
import 'package:ideco_platform/platform/domain/repositories/platform_auth_repository.dart';
import 'package:ideco_platform/platform/domain/usecases/restore_session_usecase.dart';
import 'package:ideco_platform/platform/domain/usecases/sign_in_usecase.dart';
import 'package:ideco_platform/platform/domain/usecases/sign_out_usecase.dart';
import 'package:ideco_platform/platform/presentation/cubit/platform_auth_cubit.dart';
import 'package:ideco_platform/platform/presentation/pages/login_page.dart';

/// Records the credentials it is given and answers with a fixed failure.
class RecordingRepository implements PlatformAuthRepository {
  String? username;
  String? password;
  List<AppModule>? modules;

  @override
  Future<Either<Failure, PlatformSession>> signIn({
    required String username,
    required String password,
    required List<AppModule> modules,
  }) async {
    this.username = username;
    this.password = password;
    this.modules = modules;
    return const Left(AuthFailure('اسم المستخدم أو كلمة المرور غير صحيحة'));
  }

  @override
  Future<Either<Failure, PlatformSession?>> restoreSession() async =>
      const Right(null);

  @override
  Future<Either<Failure, Unit>> signOut() async => const Right(unit);
}

Future<RecordingRepository> pumpLogin(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repository = RecordingRepository();

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
        home: const LoginPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('refuses to submit empty credentials', (tester) async {
    final repository = await pumpLogin(tester);

    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();

    expect(find.text('يرجى إدخال اسم المستخدم'), findsOneWidget);
    expect(find.text('يرجى إدخال كلمة المرور'), findsOneWidget);
    expect(repository.username, isNull);
  });

  testWidgets('submits the credentials once for every registered application',
      (tester) async {
    final repository = await pumpLogin(tester);

    await tester.enterText(
      find.byType(TextFormField).first,
      '  a.alsharif  ',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secret');
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();

    // A single submission carries the whole catalogue — that is the SSO.
    expect(repository.username, 'a.alsharif'); // trimmed
    expect(repository.password, 'secret');
    expect(repository.modules, isNotEmpty);
  });

  testWidgets('shows the server message when authentication fails',
      (tester) async {
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField).first, 'ghost');
    await tester.enterText(find.byType(TextFormField).last, 'wrong');
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();

    expect(find.text('تعذر تسجيل الدخول'), findsOneWidget);
    expect(
      find.text('اسم المستخدم أو كلمة المرور غير صحيحة'),
      findsOneWidget,
    );
  });

  testWidgets('pre-fills the username of the previous session', (tester) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = RecordingRepository();
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
          home: const LoginPage(initialUsername: 'a.alsharif'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('a.alsharif'), findsOneWidget);
  });
}
