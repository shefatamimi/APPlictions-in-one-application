/// # Employee
///
/// Platform-wide identity of the signed-in employee.
///
/// One login populates this entity once; every module reads it from the
/// session instead of authenticating again. Fields are merged from the
/// `GetAppLoginUser` rows returned for each application the employee is
/// entitled to, because the legacy service exposes different columns per
/// application id:
///
/// | Column          | app_id 20 (inspection) | app_id 49 (meter reading) |
/// |-----------------|------------------------|---------------------------|
/// | `ID`            | ✔                      | ✔                         |
/// | `EMP_NO`        | ✔                      | ✔                         |
/// | `USERNAME`      | ✔                      | —                         |
/// | `WORK_NAME`     | ✔                      | —                         |
/// | `WRK_SHOP_NUM`  | ✔                      | ✔                         |
/// | `WRK_SHOP_NAME` | —                      | ✔                         |
/// | `SYS_DESC`      | ✔                      | —                         |
///
/// Merging the rows is what lets the dashboard show a full employee card
/// (name, number, department, workshop) without a new endpoint.
library;

import 'package:equatable/equatable.dart';

class Employee extends Equatable {
  /// Internal user id (`ID`).
  final String id;

  /// Employee number (`EMP_NO`) — shown on the dashboard card.
  final String employeeNumber;

  /// Login name (`USERNAME`), also the value the backend stores as
  /// `entry_user` on every record the employee creates.
  final String username;

  /// Full display name (`SYS_DESC`, falling back to `USERNAME`).
  final String fullName;

  /// Department / job description (`WORK_NAME`).
  final String department;

  /// Workshop or office name (`WRK_SHOP_NAME`).
  final String workshopName;

  /// Workshop or office number (`WRK_SHOP_NUM`).
  final String workshopNumber;

  /// Oracle account (`ORACLE_USER`) — used by some legacy SOAP operations.
  final String oracleUser;

  /// System minor code (`SYS_MINOR`).
  final String systemMinor;

  const Employee({
    required this.id,
    required this.employeeNumber,
    required this.username,
    required this.fullName,
    required this.department,
    required this.workshopName,
    required this.workshopNumber,
    required this.oracleUser,
    required this.systemMinor,
  });

  /// Name to render, never empty: full name → username → employee number.
  String get displayName {
    if (fullName.trim().isNotEmpty) return fullName.trim();
    if (username.trim().isNotEmpty) return username.trim();
    return employeeNumber;
  }

  /// Department to render, or a dash when the service returned nothing.
  String get displayDepartment =>
      department.trim().isNotEmpty ? department.trim() : '—';

  /// Workshop / office to render. Falls back to the workshop number when the
  /// name column is absent (app_id 20 only returns the number).
  String get displayWorkshop {
    if (workshopName.trim().isNotEmpty) return workshopName.trim();
    if (workshopNumber.trim().isNotEmpty) {
      return 'ورشة ${workshopNumber.trim()}';
    }
    return '—';
  }

  /// First two letters of the display name, for the avatar monogram.
  String get initials {
    final parts =
        displayName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '؟';
    if (parts.length == 1) {
      final word = parts.first;
      return word.length <= 2 ? word : word.substring(0, 2);
    }
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}';
  }

  /// ## mergeWith
  ///
  /// **Description**: Returns a copy of this employee where every empty field
  /// is filled from [other]. Used to combine the login rows of several
  /// applications into one complete profile.
  ///
  /// **Returns**: a new [Employee]; neither operand is mutated.
  Employee mergeWith(Employee other) {
    String pick(String mine, String theirs) =>
        mine.trim().isNotEmpty ? mine : theirs;

    return Employee(
      id: pick(id, other.id),
      employeeNumber: pick(employeeNumber, other.employeeNumber),
      username: pick(username, other.username),
      fullName: pick(fullName, other.fullName),
      department: pick(department, other.department),
      workshopName: pick(workshopName, other.workshopName),
      workshopNumber: pick(workshopNumber, other.workshopNumber),
      oracleUser: pick(oracleUser, other.oracleUser),
      systemMinor: pick(systemMinor, other.systemMinor),
    );
  }

  @override
  List<Object?> get props => [
        id,
        employeeNumber,
        username,
        fullName,
        department,
        workshopName,
        workshopNumber,
        oracleUser,
        systemMinor,
      ];
}
