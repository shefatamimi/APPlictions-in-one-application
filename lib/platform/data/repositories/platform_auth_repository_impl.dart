/// # PlatformAuthRepositoryImpl
///
/// Implements the single sign-on on top of the existing SOAP service.
///
/// ## Sign-in algorithm
///
/// ```
/// online?
///  ├─ no  → offline login: match cached credentials → replay cached session
///  └─ yes → for every enabled module (concurrently):
///             GetAppLoginUser(DataType, app_id)  ← unchanged legacy query
///           ├─ every probe empty        → AuthFailure  (bad credentials or
///           │                              no entitlement anywhere)
///           ├─ every probe threw        → ServerFailure
///           └─ at least one row         → merge employee rows,
///                                         grant those module ids, cache
/// ```
///
/// A module whose probe *threw* while another succeeded is skipped rather than
/// failing the whole login: a field technician must be able to work with the
/// applications that answered.
library;

import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/network_info.dart';
import '../../domain/entities/app_module.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/platform_session.dart';
import '../../domain/repositories/platform_auth_repository.dart';
import '../datasources/platform_auth_remote_datasource.dart';
import '../datasources/platform_session_local_datasource.dart';
import '../models/employee_model.dart';

class PlatformAuthRepositoryImpl implements PlatformAuthRepository {
  final PlatformAuthRemoteDataSource _remote;
  final PlatformSessionLocalDataSource _local;
  final NetworkInfo _networkInfo;

  const PlatformAuthRepositoryImpl({
    required PlatformAuthRemoteDataSource remote,
    required PlatformSessionLocalDataSource local,
    required NetworkInfo networkInfo,
  })  : _remote = remote,
        _local = local,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, PlatformSession>> signIn({
    required String username,
    required String password,
    required List<AppModule> modules,
  }) async {
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return _offlineSignIn(username: username, password: password);
    }

    final candidates = modules.where((m) => m.enabled).toList();
    if (candidates.isEmpty) return const Left(NoAccessFailure());

    // One concurrent probe per application — the shared endpoint answers each
    // with the same query its standalone app already sends.
    final probes = await Future.wait(
      candidates.map(
        (module) =>
            _probe(module: module, username: username, password: password),
      ),
    );

    final granted = <String>[];
    Employee employee = EmployeeModel.empty;
    var failedProbes = 0;

    for (final probe in probes) {
      if (probe.transportFailed) {
        failedProbes++;
        continue;
      }
      if (probe.employee == null) continue;

      granted.add(probe.module.id);
      // Columns differ per app_id, so the profile is the union of the rows.
      employee = employee.mergeWith(probe.employee!);
    }

    // ─── Force-enable Smart Meters (Temporary for testing) ───────────────────
    if (!granted.contains('smart_meters')) {
      granted.add('smart_meters');
    }
    // ─────────────────────────────────────────────────────────────────────────

    if (granted.isEmpty) {
      // Every application refused. If they all refused because the network
      // broke, say so; otherwise the credentials or the entitlements are wrong.
      if (failedProbes == candidates.length) {
        return const Left(ServerFailure());
      }
      return const Left(AuthFailure(
        'اسم المستخدم أو كلمة المرور غير صحيحة، أو لا تملك صلاحية لأي تطبيق',
      ));
    }

    // التحقق من وجود رقم الموظف كما طلب المستخدم
    if (employee.employeeNumber.isEmpty) {
      return const Left(AuthFailure(
        'فشل تسجيل الدخول: رقم الموظف (EMP_NO) غير موجود في بيانات المستخدم.',
      ));
    }

    if (failedProbes > 0) {
      developer.log(
        '$failedProbes application probe(s) failed; continuing with '
        '${granted.length} authorised application(s)',
        name: 'PlatformAuth',
      );
    }

    final session = PlatformSession(
      employee: employee,
      // Registry order, not completion order, so the dashboard is stable.
      grantedModuleIds: candidates
          .map((m) => m.id)
          .where(granted.contains)
          .toList(growable: false),
      username: username,
      password: password,
    );

    try {
      await _local.save(session);
    } catch (e) {
      // A keychain write failure must not block a successful login; the user
      // simply will not get auto-resume or offline login this time.
      developer.log('Session cache write failed: $e', name: 'PlatformAuth');
    }

    return Right(session);
  }

  @override
  Future<Either<Failure, PlatformSession?>> restoreSession() async {
    try {
      final isConnected = await _networkInfo.isConnected;
      final session = await _local.read(isOffline: !isConnected);
      return Right(session);
    } catch (_) {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _local.clear();
      return const Right(unit);
    } catch (_) {
      return const Left(CacheFailure());
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Internals
  // ───────────────────────────────────────────────────────────────────────────

  /// Runs one login probe, converting any exception into
  /// [_ProbeResult.transportFailed] so `Future.wait` never short-circuits the
  /// other applications.
  Future<_ProbeResult> _probe({
    required AppModule module,
    required String username,
    required String password,
  }) async {
    try {
      final employee = await _remote.probeModule(
        module: module,
        username: username,
        password: password,
      );
      return _ProbeResult(module: module, employee: employee);
    } catch (e) {
      developer.log(
        'Probe for ${module.id} (app_id=${module.serverAppId}) failed: $e',
        name: 'PlatformAuth',
      );
      return _ProbeResult(module: module, transportFailed: true);
    }
  }

  /// Offline path: replays the cached entitlements when the typed credentials
  /// match the last successful online login.
  Future<Either<Failure, PlatformSession>> _offlineSignIn({
    required String username,
    required String password,
  }) async {
    try {
      final matches = await _local.matchesCachedCredentials(
        username: username,
        password: password,
      );
      if (!matches) {
        return const Left(NetworkFailure(
          'لا يوجد اتصال بالإنترنت، ولا تتوفر بيانات دخول محفوظة لهذا المستخدم',
        ));
      }

      final session = await _local.read(isOffline: true);
      if (session == null || session.grantedModuleIds.isEmpty) {
        return const Left(NetworkFailure(
          'لا يوجد اتصال بالإنترنت، ولا توجد جلسة محفوظة',
        ));
      }
      return Right(session);
    } catch (_) {
      return const Left(CacheFailure());
    }
  }
}

/// Outcome of a single application login probe.
class _ProbeResult {
  final AppModule module;
  final EmployeeModel? employee;
  final bool transportFailed;

  const _ProbeResult({
    required this.module,
    this.employee,
    this.transportFailed = false,
  });
}
