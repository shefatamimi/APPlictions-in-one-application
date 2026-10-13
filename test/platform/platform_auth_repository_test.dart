/// Behaviour of the single sign-on: one credential submission, one probe per
/// registered application, and the union of the answers becomes the employee's
/// application list.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:ideco_platform/core/errors/failures.dart';
import 'package:ideco_platform/core/network/network_info.dart';
import 'package:ideco_platform/platform/data/datasources/platform_auth_remote_datasource.dart';
import 'package:ideco_platform/platform/data/datasources/platform_session_local_datasource.dart';
import 'package:ideco_platform/platform/data/models/employee_model.dart';
import 'package:ideco_platform/platform/data/repositories/platform_auth_repository_impl.dart';
import 'package:ideco_platform/platform/domain/entities/app_module.dart';
import 'package:ideco_platform/platform/domain/entities/platform_session.dart';
import 'package:ideco_platform/platform/registry/app_registry.dart';

// ─── Fakes ───────────────────────────────────────────────────────────────────

class FakeNetwork implements NetworkInfo {
  FakeNetwork(this.connected);
  final bool connected;

  @override
  Future<bool> get isConnected async => connected;
}

/// Answers each probe from a per-app-id script: an [EmployeeModel] to authorise
/// the application, `null` to refuse it, or a thrown error for a transport
/// failure.
class ScriptedRemote implements PlatformAuthRemoteDataSource {
  ScriptedRemote(this.script);

  final Map<int, Object?> script;
  final List<String> queriedAppIds = [];

  @override
  Future<EmployeeModel?> probeModule({
    required AppModule module,
    required String username,
    required String password,
  }) async {
    queriedAppIds.add('${module.serverAppId}:${module.loginDataType}');
    final answer = script[module.serverAppId];
    if (answer is Exception) throw answer;
    return answer as EmployeeModel?;
  }
}

class MemoryStore implements PlatformSessionLocalDataSource {
  PlatformSession? saved;
  bool cleared = false;

  @override
  Future<void> save(PlatformSession session) async => saved = session;

  @override
  Future<PlatformSession?> read({bool isOffline = false}) async =>
      saved?.copyWith(isOffline: isOffline);

  @override
  Future<bool> matchesCachedCredentials({
    required String username,
    required String password,
  }) async =>
      saved != null &&
      saved!.username == username &&
      saved!.password == password;

  @override
  Future<void> clear() async {
    saved = null;
    cleared = true;
  }
}

// ─── Fixtures ────────────────────────────────────────────────────────────────

const _inspectionRow = EmployeeModel(
  id: '4321',
  employeeNumber: '1187',
  username: 'a.alsharif',
  fullName: 'أسعد الشريف',
  department: 'قسم مكافحة سرقات التيار',
  workshopName: '',
  workshopNumber: '7',
  oracleUser: 'IDECO_APP',
  systemMinor: '3',
);

const _meterReadingRow = EmployeeModel(
  id: '4321',
  employeeNumber: '1187',
  username: '',
  fullName: '',
  department: '',
  workshopName: 'ورشة إربد الشمالية',
  workshopNumber: '7',
  oracleUser: '',
  systemMinor: '',
);

PlatformAuthRepositoryImpl buildRepository({
  required Map<int, Object?> script,
  bool online = true,
  MemoryStore? store,
}) {
  return PlatformAuthRepositoryImpl(
    remote: ScriptedRemote(script),
    local: store ?? MemoryStore(),
    networkInfo: FakeNetwork(online),
  );
}

void main() {
  group('signIn — permission resolution', () {
    test('grants both applications when both answer', () async {
      final store = MemoryStore();
      final repository = buildRepository(
        script: {20: _inspectionRow, 49: _meterReadingRow},
        store: store,
      );

      final result = await repository.signIn(
        username: 'a.alsharif',
        password: 'secret',
        modules: AppRegistry.modules,
      );

      final session =
          result.getOrElse(() => throw StateError('expected Right'));
      expect(session.grantedModuleIds, ['inspection', 'meter_reading']);
      expect(session.hasSingleApp, isFalse);

      // The profile is the union of the two rows.
      expect(session.employee.fullName, 'أسعد الشريف');
      expect(session.employee.workshopName, 'ورشة إربد الشمالية');

      // And the session is cached for auto-resume / offline login.
      expect(store.saved?.grantedModuleIds, ['inspection', 'meter_reading']);
    });

    test('grants only the application the server authorises', () async {
      final repository = buildRepository(
        script: {20: null, 49: _meterReadingRow},
      );

      final result = await repository.signIn(
        username: 'reader',
        password: 'secret',
        modules: AppRegistry.modules,
      );

      final session =
          result.getOrElse(() => throw StateError('expected Right'));
      expect(session.grantedModuleIds, ['meter_reading']);
      expect(session.hasSingleApp, isTrue);
      expect(session.canAccess('inspection'), isFalse);
    });

    test('sends each application its own DataType and app_id', () async {
      final remote = ScriptedRemote({20: _inspectionRow, 49: _meterReadingRow});
      final repository = PlatformAuthRepositoryImpl(
        remote: remote,
        local: MemoryStore(),
        networkInfo: FakeNetwork(true),
      );

      await repository.signIn(
        username: 'a.alsharif',
        password: 'secret',
        modules: AppRegistry.modules,
      );

      // Exactly the queries the standalone applications already send.
      expect(remote.queriedAppIds, containsAll(['20:14', '49:1']));
    });

    test('fails with AuthFailure when every application refuses', () async {
      final repository = buildRepository(script: {20: null, 49: null});

      final result = await repository.signIn(
        username: 'ghost',
        password: 'wrong',
        modules: AppRegistry.modules,
      );

      expect(result.isLeft(), isTrue);
      result.fold((failure) => expect(failure, isA<AuthFailure>()), (_) {});
    });

    test('fails with ServerFailure when every probe throws', () async {
      final repository = buildRepository(
        script: {
          20: Exception('socket closed'),
          49: Exception('socket closed'),
        },
      );

      final result = await repository.signIn(
        username: 'a.alsharif',
        password: 'secret',
        modules: AppRegistry.modules,
      );

      result.fold((failure) => expect(failure, isA<ServerFailure>()), (_) {});
    });

    test('one failing probe does not block the applications that answered',
        () async {
      final repository = buildRepository(
        script: {20: _inspectionRow, 49: Exception('timeout')},
      );

      final result = await repository.signIn(
        username: 'a.alsharif',
        password: 'secret',
        modules: AppRegistry.modules,
      );

      final session =
          result.getOrElse(() => throw StateError('expected Right'));
      expect(session.grantedModuleIds, ['inspection']);
    });
  });

  group('signIn — offline', () {
    test('replays the cached entitlements for matching credentials', () async {
      final store = MemoryStore();

      // First login online, then go offline with the same repository state.
      await buildRepository(
        script: {20: _inspectionRow, 49: _meterReadingRow},
        store: store,
      ).signIn(
        username: 'a.alsharif',
        password: 'secret',
        modules: AppRegistry.modules,
      );

      final offline = buildRepository(
        script: const {},
        online: false,
        store: store,
      );
      final result = await offline.signIn(
        username: 'a.alsharif',
        password: 'secret',
        modules: AppRegistry.modules,
      );

      final session =
          result.getOrElse(() => throw StateError('expected Right'));
      expect(session.isOffline, isTrue);
      expect(session.grantedModuleIds, ['inspection', 'meter_reading']);
    });

    test('refuses credentials that were never cached', () async {
      final offline = buildRepository(script: const {}, online: false);

      final result = await offline.signIn(
        username: 'someone.else',
        password: 'secret',
        modules: AppRegistry.modules,
      );

      result.fold((failure) => expect(failure, isA<NetworkFailure>()), (_) {});
    });
  });

  group('session lifecycle', () {
    test('signOut clears the cached session', () async {
      final store = MemoryStore();
      final repository = buildRepository(
        script: {20: _inspectionRow, 49: null},
        store: store,
      );

      await repository.signIn(
        username: 'a.alsharif',
        password: 'secret',
        modules: AppRegistry.modules,
      );
      expect(store.saved, isNotNull);

      await repository.signOut();
      expect(store.cleared, isTrue);
      expect(store.saved, isNull);

      final restored = await repository.restoreSession();
      expect(restored.getOrElse(() => null), isNull);
    });
  });
}
