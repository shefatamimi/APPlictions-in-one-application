/// # SubmissionModel
///
/// Data model for a single illegal-notification record.  Extends
/// [SubmissionEntity] and adds XML parsing from the `GetIllegalNotification`
/// SOAP response (DataType:18).
library;

import 'package:xml/xml.dart';

import '../../domain/entities/submission_entity.dart';

class SubmissionModel extends SubmissionEntity {
  const SubmissionModel({
    required super.id,
    required super.cityId,
    required super.custId,
    required super.custName,
    required super.uncustName,
    required super.address,
    required super.mobile,
    required super.meterNum,
    required super.lastReading,
    required super.headNotes,
    required super.engNotes,
    required super.illStep,
    required super.pid,
    required super.illegalDate,
    required super.empName,
    required super.workshopName,
    required super.transRequestType,
    required super.posX,
    required super.posY,
  });

  // ---------------------------------------------------------------------------
  // XML parsing
  // ---------------------------------------------------------------------------

  /// Parses a list of [SubmissionModel] records from the raw SOAP response
  /// XML of `GetIllegalNotification`.
  ///
  /// Handles both namespaced and namespace-free element names, and falls back
  /// gracefully when fields are missing or malformed.
  static List<SubmissionModel> fromXmlList(String xmlBody) {
    final results = <SubmissionModel>[];
    try {
      final doc = XmlDocument.parse(xmlBody);

      // Walk every element regardless of namespace prefix
      final rows = doc.descendants
          .whereType<XmlElement>()
          .where((e) => e.localName == 'Table' || e.localName == 'Table1')
          .toList();

      for (final row in rows) {
        results.add(_fromRow(row));
      }

      if (results.isEmpty) {
        // Fallback: any element with an "ID" child
        final fallback = doc.descendants
            .whereType<XmlElement>()
            .where((e) => _child(e, 'ID').isNotEmpty)
            .toList();
        for (final row in fallback) {
          results.add(_fromRow(row));
        }
      }
    } catch (_) {}
    return results;
  }

  static SubmissionModel _fromRow(XmlElement row) {
    return SubmissionModel(
      id: _child(row, 'ID'),
      cityId: _child(row, 'CITY_ID'),
      custId: _child(row, 'CUST_ID'),
      custName: _child(row, 'CUST_NAME'),
      uncustName: _child(row, 'UNCUST_NAME'),
      address: _child(row, 'ADDRESS'),
      mobile: _child(row, 'MOBILE'),
      meterNum: _child(row, 'CUSM_M_NUM'),
      lastReading: _child(row, 'CUSM_M_LREAD'),
      headNotes: _child(row, 'HEAD_NOTES'),
      engNotes: _child(row, 'ENG_NOTES'),
      illStep: _child(row, 'ILL_STEP'),
      pid: _child(row, 'PID'),
      illegalDate: _child(row, 'ILLEGAL_DATE'),
      empName: _child(row, 'EMP_NAME'),
      workshopName: _child(row, 'WORKSHOP_NAME'),
      transRequestType: _child(row, 'TRANS_REQUST_TYPE'),
      posX: _child(row, 'CUSM_X_POSITION'),
      posY: _child(row, 'CUSM_Y_POSITION'),
    );
  }

  /// Returns the inner text of the first child element whose `localName`
  /// matches [name], or an empty string if not found.
  static String _child(XmlElement parent, String name) {
    try {
      return parent.descendants
          .whereType<XmlElement>()
          .firstWhere((e) => e.localName == name)
          .innerText
          .trim();
    } catch (_) {
      return '';
    }
  }
}
