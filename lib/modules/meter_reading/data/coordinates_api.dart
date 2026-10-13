/// # CoordinatesApi
///
/// Data source of the meter-reading / coordinate-capture module.
///
/// Every operation, SOAP action, property name and query string below is
/// **verbatim** what the standalone `Coordinates` application sends today; only
/// the transport was swapped for the platform's shared [SoapClient] so all
/// modules go through one endpoint, one timeout policy and one log channel.
/// The service contract is therefore untouched.
///
/// | Operation                                | Payload                        |
/// |------------------------------------------|--------------------------------|
/// | `GetGenericsDataTable`                   | RSA `data` = `DataType:60,SYSMajor:<major>` |
/// | `GET_COORDINATE_APP_DATA`                | plain `where` + `dataType`     |
/// | `InsertCoordinates`                      | plain field list + Base64 image|
/// | `GetWFTRANSACTIONSBiIllegalProcessNote`  | plain `where`                  |
library;

import 'dart:developer' as developer;

import 'package:xml/xml.dart';

import '../../../core/network/soap_client.dart';
import '../../../core/utils/rsa_helper.dart';
import 'models/coordinate_details.dart';
import 'models/field_transaction.dart';
import 'models/generic_type.dart';
import 'models/geo_point.dart';

class CoordinatesApi {
  final SoapClient _soap;

  const CoordinatesApi(this._soap);

  // ─── Operation names (unchanged) ───────────────────────────────────────────

  static const String _genericsMethod = 'GetGenericsDataTable';
  static const String _coordinateDataMethod = 'GET_COORDINATE_APP_DATA';
  static const String _insertMethod = 'InsertCoordinates';
  static const String _transactionsMethod =
      'GetWFTRANSACTIONSBiIllegalProcessNote';

  static const String _actionPrefix = 'http://tempuri.org/IBillingWcfsrv';

  /// NOTE — kept exactly as the standalone application sends it. The interface
  /// segment is `IIdecoWcfsrv` here while every other operation uses
  /// `IBillingWcfsrv`; that difference is pre-existing behaviour and is
  /// preserved so the platform introduces no protocol change. If the inquiry
  /// screen comes back empty on the server, this is the line to verify first.
  static const String _transactionsAction =
      'http://tempuri.org/IIdecoWcfsrv/GetWFTRANSACTIONSBiIllegalProcessNote';

  /// Lookup group of the geo-taggable record types.
  static const int recordTypesMajor = 324;

  // ─── Record types ──────────────────────────────────────────────────────────

  /// ## fetchRecordTypes
  ///
  /// **SOAP Method**: `GetGenericsDataTable`
  /// **SOAP Action**: `http://tempuri.org/IBillingWcfsrv/GetGenericsDataTable`
  ///
  /// **Description**: Loads the record types that can be geo-stamped
  /// (transaction, subscription, transformer, pole …).
  ///
  /// **Request payload** (RSA-encrypted): `DataType:60,SYSMajor:<major>`
  ///
  /// **Returns**: the `dtGeneric` rows; an empty list when the service answers
  /// with a fault or no rows.
  ///
  /// **Throws**: [Exception] on transport failure.
  Future<List<GenericType>> fetchRecordTypes({
    int major = recordTypesMajor,
  }) async {
    final encrypted = RsaHelper.encrypt('DataType:60,SYSMajor:$major');

    final xmlBody = await _soap.call(
      methodName: _genericsMethod,
      soapAction: '$_actionPrefix/$_genericsMethod',
      bodyProperties: {'data': encrypted},
    );

    return _parseRecordTypes(xmlBody);
  }

  // ─── Record lookup ─────────────────────────────────────────────────────────

  /// ## searchRecord
  ///
  /// **SOAP Method**: `GET_COORDINATE_APP_DATA`
  ///
  /// **Description**: Looks up the record the technician is about to stamp.
  /// The `where` clause per record type is unchanged:
  ///
  /// * `1` transaction  → `and d.main_pid = '<value>'`
  /// * `2` subscription → `where LPAD(cmf.cusm_city,3,'0')||LPAD(cmf.CUSM_NUM,7,'0') = '<value>'`
  /// * `3` transformer  → `and t.CONVERTER_CODE = '<value>'`
  /// * `4` pole         → `and POLE_NO = '<value>'`
  ///
  /// **Returns**: matching rows, empty when the number does not exist.
  ///
  /// **Throws**: [Exception] on transport failure, [ArgumentError] for an
  /// unsupported [typeMinor].
  Future<List<CoordinateDetails>> searchRecord({
    required String typeMinor,
    required String value,
  }) async {
    final where = switch (typeMinor) {
      '1' => " and d.main_pid= '$value'",
      '2' =>
        " where LPAD(cmf.cusm_city,3,'0')||LPAD(cmf.CUSM_NUM,7,'0') = '$value'",
      '3' => " and t.CONVERTER_CODE= '$value'",
      '4' => " and POLE_NO = '$value'",
      _ => throw ArgumentError('نوع غير مدعوم: $typeMinor'),
    };

    final xmlBody = await _soap.call(
      methodName: _coordinateDataMethod,
      soapAction: '$_actionPrefix/$_coordinateDataMethod',
      bodyProperties: {'where': where, 'dataType': typeMinor},
    );

    return _parseDetails(xmlBody);
  }

  /// ## fetchTodayPoints
  ///
  /// **SOAP Method**: `GET_COORDINATE_APP_DATA`
  ///
  /// **Description**: Points the signed-in employee already captured today,
  /// drawn as green markers so nothing is stamped twice.
  ///
  /// **Request payload**:
  /// `and entry_user = '<username>' and TRUNC(entry_date) = TRUNC(SYSDATE)`
  ///
  /// **Returns**: valid positions only; malformed rows are dropped.
  ///
  /// **Throws**: [Exception] on transport failure.
  Future<List<GeoPoint>> fetchTodayPoints(String username) async {
    final xmlBody = await _soap.call(
      methodName: _coordinateDataMethod,
      soapAction: '$_actionPrefix/$_coordinateDataMethod',
      bodyProperties: {
        'where':
            " and entry_user = '$username' and TRUNC(entry_date) = TRUNC(SYSDATE) ",
      },
    );

    return _parseTodayPoints(xmlBody);
  }

  // ─── Capture ───────────────────────────────────────────────────────────────

  /// ## insertCoordinates
  ///
  /// **SOAP Method**: `InsertCoordinates`
  ///
  /// **Description**: Stores the captured position with its record reference,
  /// notes and field photo. Property names and order are unchanged.
  ///
  /// **Returns**: the service's numeric result (`>= 0` means stored), or `null`
  /// when the response carries no readable result element. `null` is
  /// deliberately **not** treated as a failure by the caller: the standalone
  /// application never inspected this value, so reporting an error for an
  /// unexpected-but-successful response shape would be a regression.
  ///
  /// **Throws**: [Exception] on transport failure.
  Future<int?> insertCoordinates({
    required String longitude,
    required String latitude,
    required String entryUser,
    required String typeMinor,
    required String typeName,
    required String recordNumber,
    required String meterNo,
    required String operationNo,
    required String note,
    required String imageBase64,
  }) async {
    final xmlBody = await _soap.call(
      methodName: _insertMethod,
      soapAction: '$_actionPrefix/$_insertMethod',
      bodyProperties: {
        'longitude': longitude,
        'latitude': latitude,
        'entryUser': entryUser,
        'type': typeMinor,
        'name': typeName,
        'Desc': recordNumber,
        'meterNo': meterNo,
        'operationNo': operationNo,
        'note': note,
        'Image': imageBase64,
      },
    );

    return _parseInsertResult(xmlBody);
  }

  // ─── Transactions inquiry ──────────────────────────────────────────────────

  /// ## searchTransactions
  ///
  /// **SOAP Method**: `GetWFTRANSACTIONSBiIllegalProcessNote`
  /// **SOAP Action**: see [_transactionsAction]
  ///
  /// **Description**: Filtered workflow-transaction search used by the module's
  /// inquiry screen. The `where` clause is assembled exactly as before.
  ///
  /// **Returns**: matching rows, empty on no match or a service fault.
  ///
  /// **Throws**: [Exception] on transport failure.
  Future<List<FieldTransaction>> searchTransactions({
    String? employeeName,
    String? date,
    String? section,
    String? subscriptionNo,
    String? meterNo,
    String? operationNo,
    String? type,
  }) async {
    var where = ' 1=1 ';

    void add(String? value, String clause) {
      if (value != null && value.isNotEmpty) where += clause;
    }

    add(employeeName, " and upper(EMP_NAME) like upper('%$employeeName%')");
    add(date, " and TRUNC(ENTRY_DATE) = TO_DATE('$date', 'YYYY-MM-DD')");
    add(section, " and SECTION = '$section'");
    add(subscriptionNo, " and CUSM_NUM = '$subscriptionNo'");
    add(meterNo, " and METER_NO = '$meterNo'");
    add(operationNo, " and OPERATION_NO = '$operationNo'");
    add(type, " and TRANS_TYPE = '$type'");

    final xmlBody = await _soap.call(
      methodName: _transactionsMethod,
      soapAction: _transactionsAction,
      bodyProperties: {'where': where},
    );

    return _parseTransactions(xmlBody);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Parsing — same tolerant strategy as the original module: look for the
  // named DataSet table first, then fall back to generic `Table` rows.
  // ───────────────────────────────────────────────────────────────────────────

  static List<GenericType> _parseRecordTypes(String xmlBody) {
    return _rows(xmlBody, 'dtGeneric')
        .map(
          (row) => GenericType(
            description: _text(row, 'SYS_DESC'),
            major: _text(row, 'SYS_MAJOR'),
            minor: _text(row, 'SYS_MINOR'),
          ),
        )
        .where((type) => type.description.isNotEmpty && type.minor.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  static List<CoordinateDetails> _parseDetails(String xmlBody) {
    return _rows(xmlBody, 'dtCoordinates')
        .map(
          (row) => CoordinateDetails(
            label1: _text(row, 'LABEL1'),
            label2: _text(row, 'LABEL2'),
            label3: _text(row, 'LABEL3'),
            label4: _text(row, 'LABEL4'),
            meterNo: _text(row, 'METER_NO'),
            operationNo: _text(row, 'OPERATION_NO'),
            notes: _text(row, 'NOTE'),
            latitude: double.tryParse(_text(row, 'LATITUDE')),
            longitude: double.tryParse(_text(row, 'LONGITUDE')),
          ),
        )
        .toList(growable: false);
  }

  static List<GeoPoint> _parseTodayPoints(String xmlBody) {
    return _rows(xmlBody, 'dtLocations')
        .map(
          (row) => GeoPoint(
            double.tryParse(_text(row, 'LATITUDE')) ?? 0,
            double.tryParse(_text(row, 'LONGITUDE')) ?? 0,
          ),
        )
        .where((point) => point.isValid)
        .toList(growable: false);
  }

  static List<FieldTransaction> _parseTransactions(String xmlBody) {
    return _rows(xmlBody, 'dtTransactions')
        .map(
          (row) => FieldTransaction(
            province: _text(row, 'PROVINCE'),
            town: _text(row, 'TOWN'),
            subscriptionNo: _text(row, 'CUSM_NUM'),
            type: _text(row, 'TRANS_TYPE'),
            phase: _text(row, 'PHASE'),
            transformerNo: _text(row, 'TRANSFORMER_NO'),
            employeeName: _text(row, 'EMP_NAME'),
            section: _text(row, 'SECTION'),
            date: _text(row, 'ENTRY_DATE'),
            operationNo: _text(row, 'OPERATION_NO'),
            meterNo: _text(row, 'METER_NO'),
            dls: _text(row, 'DLS'),
            x: _text(row, 'COORD_X'),
            y: _text(row, 'COORD_Y'),
          ),
        )
        .toList(growable: false);
  }

  static int? _parseInsertResult(String xmlBody) {
    try {
      final document = XmlDocument.parse(xmlBody);
      final result = document
          .findAllElements('${_insertMethod}Result')
          .map((e) => e.innerText.trim())
          .where((text) => text.isNotEmpty)
          .firstOrNull;
      if (result == null) return null;
      return int.tryParse(result);
    } catch (e) {
      developer.log('InsertCoordinates parse failed: $e', name: 'MeterReading');
      return null;
    }
  }

  /// Finds the data rows of a .NET DataSet response.
  ///
  /// Tries the documented table name first, then any `Table` / `Table1`
  /// element, and finally unwraps a response whose payload is an escaped XML
  /// string rather than nested elements.
  static Iterable<XmlElement> _rows(String xmlBody, String tableName) {
    if (xmlBody.trim().isEmpty) return const [];

    try {
      final document = XmlDocument.parse(xmlBody);

      var rows = document.findAllElements(tableName);
      if (rows.isEmpty) {
        rows = document.descendants.whereType<XmlElement>().where((e) {
          final name = e.name.local.toLowerCase();
          return name == tableName.toLowerCase() ||
              name == 'table' ||
              name == 'table1';
        });
      }

      if (rows.isEmpty) {
        // Some operations return the DataSet as an escaped string payload.
        final inner = document.descendants
            .whereType<XmlElement>()
            .where((e) => e.name.local.endsWith('Result'))
            .map((e) => e.innerText)
            .where((text) => text.contains('<'))
            .firstOrNull;
        if (inner != null) return _rows(inner, tableName);
      }

      return rows.toList(growable: false);
    } catch (e) {
      developer.log('Response parse failed ($tableName): $e',
          name: 'MeterReading');
      return const [];
    }
  }

  /// Reads a column by name, case-insensitively, or `''` when absent.
  static String _text(XmlElement row, String column) {
    final direct = row.findElements(column).firstOrNull;
    if (direct != null) return direct.innerText.trim();

    final loose = row.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local.toLowerCase() == column.toLowerCase())
        .firstOrNull;
    return loose?.innerText.trim() ?? '';
  }
}
