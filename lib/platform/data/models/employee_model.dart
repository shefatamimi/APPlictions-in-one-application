/// # EmployeeModel
///
/// Data-layer model that parses the `GetAppLoginUser` SOAP response into an
/// [Employee].
///
/// ## Why one parser for two applications
///
/// The legacy service serialises a .NET `DataSet`, so the payload is
/// `soap:Body → *Response → *Result → diffgr:diffgram → NewDataSet → <row>`.
/// The row element is named `Table` for `app_id 20` and `tblusers` for
/// `app_id 49`, and each exposes a different subset of columns. Rather than
/// hard-coding either shape, this parser walks to the first row element that
/// carries an `ID` child and reads columns by local name — so a third
/// application with a fourth row name works without a code change.
library;

import 'package:xml/xml.dart';

import '../../domain/entities/employee.dart';

class EmployeeModel extends Employee {
  const EmployeeModel({
    required super.id,
    required super.employeeNumber,
    required super.username,
    required super.fullName,
    required super.department,
    required super.workshopName,
    required super.workshopNumber,
    required super.oracleUser,
    required super.systemMinor,
  });

  /// An employee with every field blank — the neutral element of
  /// [Employee.mergeWith].
  static const EmployeeModel empty = EmployeeModel(
    id: '',
    employeeNumber: '',
    username: '',
    fullName: '',
    department: '',
    workshopName: '',
    workshopNumber: '',
    oracleUser: '',
    systemMinor: '',
  );

  /// ## fromXml
  ///
  /// **SOAP Method**: `GetAppLoginUser`
  /// **SOAP Action**: `http://tempuri.org/IBillingWcfsrv/GetAppLoginUser`
  /// **Endpoint**: `https://ideco.com.jo/IDECO_API_PROD/IdecoWcfsrv.svc`
  ///
  /// **Description**: Extracts the first user row from a raw
  /// `GetAppLoginUser` response. An empty result set means "these credentials
  /// are not authorised for this `app_id`" — which is precisely the signal the
  /// platform uses to decide whether to show the application's card.
  ///
  /// **Returns**: an [EmployeeModel], or `null` when the response contains no
  /// usable row (wrong credentials, or no permission for this application).
  ///
  /// **Throws**: never — malformed XML yields `null`.
  static EmployeeModel? fromXml(String xmlBody) {
    if (xmlBody.trim().isEmpty) return null;

    try {
      final document = XmlDocument.parse(xmlBody);
      final row = _findUserRow(document);
      if (row == null) return null;

      final id = _text(row, 'ID');
      if (id.isEmpty || id == '-1') return null;

      final username = _text(row, 'USERNAME');
      final sysDesc = _text(row, 'SYS_DESC');

      return EmployeeModel(
        id: id,
        employeeNumber: _text(row, 'EMP_NO'),
        username: username,
        // app_id 20 returns the readable name in SYS_DESC; app_id 49 returns
        // no name column at all, so the merge fills it from the other row.
        fullName: sysDesc.isNotEmpty ? sysDesc : username,
        department: _text(row, 'WORK_NAME'),
        workshopName: _text(row, 'WRK_SHOP_NAME'),
        workshopNumber: _text(row, 'WRK_SHOP_NUM'),
        oracleUser: _text(row, 'ORACLE_USER'),
        systemMinor: _text(row, 'SYS_MINOR'),
      );
    } catch (_) {
      return null;
    }
  }

  /// Rebuilds a model from the flat map persisted in secure storage.
  factory EmployeeModel.fromJson(Map<String, String> map) {
    return EmployeeModel(
      id: map['id'] ?? '',
      employeeNumber: map['employee_number'] ?? '',
      username: map['username'] ?? '',
      fullName: map['full_name'] ?? '',
      department: map['department'] ?? '',
      workshopName: map['workshop_name'] ?? '',
      workshopNumber: map['workshop_number'] ?? '',
      oracleUser: map['oracle_user'] ?? '',
      systemMinor: map['system_minor'] ?? '',
    );
  }

  /// Wraps a domain [Employee] so it can be serialised.
  factory EmployeeModel.fromEntity(Employee employee) {
    return EmployeeModel(
      id: employee.id,
      employeeNumber: employee.employeeNumber,
      username: employee.username,
      fullName: employee.fullName,
      department: employee.department,
      workshopName: employee.workshopName,
      workshopNumber: employee.workshopNumber,
      oracleUser: employee.oracleUser,
      systemMinor: employee.systemMinor,
    );
  }

  /// Flat map for secure storage.
  Map<String, String> toJson() => {
        'id': id,
        'employee_number': employeeNumber,
        'username': username,
        'full_name': fullName,
        'department': department,
        'workshop_name': workshopName,
        'workshop_number': workshopNumber,
        'oracle_user': oracleUser,
        'system_minor': systemMinor,
      };

  // ───────────────────────────────────────────────────────────────────────────
  // Parsing helpers
  // ───────────────────────────────────────────────────────────────────────────

  /// Locates the first data row of the .NET `DataSet`, tolerating every row
  /// element name the service is known to emit (`Table`, `tblusers`, …).
  static XmlElement? _findUserRow(XmlDocument document) {
    // Strategy 1 — walk the diffgram: diffgram → NewDataSet → first row.
    final diffgram = document.descendants
        .whereType<XmlElement>()
        .where((e) => e.localName == 'diffgram')
        .firstOrNull;

    final row = diffgram?.childElements.firstOrNull?.childElements.firstOrNull;
    if (row != null && _hasId(row)) return row;

    // Strategy 2 — any element that directly carries a non-empty <ID> child.
    return document.descendants
        .whereType<XmlElement>()
        .where(_hasId)
        .firstOrNull;
  }

  static bool _hasId(XmlElement element) {
    final id =
        element.childElements.where((c) => c.localName == 'ID').firstOrNull;
    return id != null && id.innerText.trim().isNotEmpty;
  }

  /// Reads a column by local name (namespace-safe), or `''` when absent.
  static String _text(XmlElement row, String column) {
    final match =
        row.childElements.where((e) => e.localName == column).firstOrNull;
    return match?.innerText.trim() ?? '';
  }
}
