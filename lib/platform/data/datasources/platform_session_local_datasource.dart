/// # PlatformSessionLocalDataSource
///
/// Persists the single sign-on session in `flutter_secure_storage`
/// (Android Keystore / iOS Keychain).
///
/// Two reasons the session is stored at all:
///
/// 1. **Auto-resume** — the splash screen restores the dashboard without a
///    second login while the session is on the device.
/// 2. **Offline login** — field crews frequently work with no coverage. The
///    original applications both supported this, and the platform keeps it:
///    credentials typed offline are matched against the last successful login
///    and the cached entitlements are replayed.
///
/// Nothing sensitive is written to plain preferences; the password never leaves
/// the keychain.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/platform_session.dart';
import '../models/employee_model.dart';

class _Keys {
  static const employeePrefix = 'platform_employee_';
  static const grantedModules = 'platform_granted_modules';
  static const username = 'platform_username';
  static const password = 'platform_password';

  /// Columns of the persisted employee record.
  static const employeeFields = [
    'id',
    'employee_number',
    'username',
    'full_name',
    'department',
    'workshop_name',
    'workshop_number',
    'oracle_user',
    'system_minor',
  ];
}

abstract class PlatformSessionLocalDataSource {
  /// Writes [session] (employee, entitlements and credentials) to the keychain.
  Future<void> save(PlatformSession session);

  /// Reads the cached session, or `null` when the device has none.
  ///
  /// [isOffline] marks the restored session as stale so screens can warn.
  Future<PlatformSession?> read({bool isOffline = false});

  /// `true` when [username] / [password] match the last successful login.
  Future<bool> matchesCachedCredentials({
    required String username,
    required String password,
  });

  /// Removes every session key. Called on logout.
  Future<void> clear();
}

class PlatformSessionLocalDataSourceImpl
    implements PlatformSessionLocalDataSource {
  final FlutterSecureStorage _storage;

  const PlatformSessionLocalDataSourceImpl(this._storage);

  @override
  Future<void> save(PlatformSession session) async {
    final employee = EmployeeModel.fromEntity(session.employee).toJson();

    for (final entry in employee.entries) {
      await _storage.write(
        key: '${_Keys.employeePrefix}${entry.key}',
        value: entry.value,
      );
    }

    await _storage.write(
      key: _Keys.grantedModules,
      value: session.grantedModuleIds.join(','),
    );
    await _storage.write(key: _Keys.username, value: session.username);
    await _storage.write(key: _Keys.password, value: session.password);

    // Save to SharedPreferences for compatibility with legacy features
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', session.username);
    await prefs.setString('password', session.password);
    await prefs.setString('ID', session.employee.id);
    await prefs.setString('EMP_NO', session.employee.employeeNumber);
    await prefs.setString('ORACLE_USER', session.employee.oracleUser);
    await prefs.setString('SYS_MINOR', session.employee.systemMinor);
    await prefs.setString('name', session.employee.fullName);
  }

  @override
  Future<PlatformSession?> read({bool isOffline = false}) async {
    final id = await _storage.read(key: '${_Keys.employeePrefix}id');
    if (id == null || id.isEmpty) return null;

    final employeeMap = <String, String>{};
    for (final field in _Keys.employeeFields) {
      employeeMap[field] =
          await _storage.read(key: '${_Keys.employeePrefix}$field') ?? '';
    }

    final granted = (await _storage.read(key: _Keys.grantedModules) ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return PlatformSession(
      employee: EmployeeModel.fromJson(employeeMap),
      grantedModuleIds: granted,
      username: await _storage.read(key: _Keys.username) ?? '',
      password: await _storage.read(key: _Keys.password) ?? '',
      isOffline: isOffline,
    );
  }

  @override
  Future<bool> matchesCachedCredentials({
    required String username,
    required String password,
  }) async {
    final cachedUser = await _storage.read(key: _Keys.username);
    final cachedPass = await _storage.read(key: _Keys.password);
    if (cachedUser == null || cachedPass == null) return false;
    return cachedUser == username && cachedPass == password;
  }

  @override
  Future<void> clear() async {
    for (final field in _Keys.employeeFields) {
      await _storage.delete(key: '${_Keys.employeePrefix}$field');
    }
    await _storage.delete(key: _Keys.grantedModules);
    await _storage.delete(key: _Keys.username);
    await _storage.delete(key: _Keys.password);

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
