/// # OperationModel
///
/// Data-layer model extending [OperationEntity] with SOAP XML parsing.
///
/// ## SOAP Calls
///
/// 1. **`GetWFTRANSACTIONSBiIllegalProcessNote`** (DataType:2)
///    Query: `DataType:2;Where: and t.MAIN_PID = {pid}`
///    Fields: `CITY`, `CUSTOMER_ID`
///
/// 2. **`GetBiIllegalProcessNote`** (DataType:1)
///    Query: `DataType:1;strWhereOracle:  and n.pid={pid}`
///    Fields: `ENG_EMP_NUMBER`, `ENG_ILL_NOTE`, `ENG_EMP_NAME`, `WRK_NAME`,
///            `WRK_NO`, `ENG_APP_APPROVAL_STATE`, `D`, `STAMP_NUM`, `ILL_NOTES`
library;

import 'package:xml/xml.dart';

import '../../domain/entities/operation_entity.dart';

class OperationModel extends OperationEntity {
  const OperationModel({
    required super.pid,
    required super.city,
    required super.subscriptionNum,
    required super.engineerName,
    required super.engineerNumber,
    required super.workshopName,
    required super.workshopNumber,
    required super.engineerNote,
    required super.stampNumber,
    required super.notes,
    required super.date,
    required super.approvalState,
    required super.isFound,
  });

  // ---------------------------------------------------------------------------
  // fromWfXml — parses DataType:2 response (city + subscription)
  // ---------------------------------------------------------------------------

  /// ## fromWfXml
  ///
  /// **SOAP Method**: `GetWFTRANSACTIONSBiIllegalProcessNote`
  /// **SOAPAction**: `http://tempuri.org/IBillingWcfsrv/GetWFTRANSACTIONSBiIllegalProcessNote`
  /// **Query DataType**: 2
  ///
  /// **Description**: Parses the workflow transaction response for a PID,
  /// extracting city and subscription number. Returns a partial model;
  /// call [withProcessNote] afterwards to merge in the note data.
  ///
  /// **Parameters**:
  /// - [xmlBody] — Raw SOAP response XML.
  /// - [pid] — The operation PID used for this query.
  ///
  /// **Returns**: Partial [OperationModel] (city + subscriptionNum populated),
  /// or a not-found model if no rows exist.
  ///
  /// **Throws**: Never.
  static OperationModel fromWfXml(String xmlBody, String pid) {
    try {
      final row = _findFirstRow(xmlBody);
      if (row == null) {
        return OperationModel(
          pid: pid,
          city: '',
          subscriptionNum: '',
          engineerName: '',
          engineerNumber: '',
          workshopName: '',
          workshopNumber: '',
          engineerNote: '',
          stampNumber: '',
          notes: '',
          date: '',
          approvalState: '',
          isFound: false,
        );
      }
      return OperationModel(
        pid: pid,
        city: _txt(row, 'CITY'),
        subscriptionNum: _txt(row, 'CUSTOMER_ID'),
        engineerName: '',
        engineerNumber: '',
        workshopName: '',
        workshopNumber: '',
        engineerNote: '',
        stampNumber: '',
        notes: '',
        date: '',
        approvalState: '',
        isFound: true,
      );
    } catch (_) {
      return OperationModel(
        pid: pid,
        city: '',
        subscriptionNum: '',
        engineerName: '',
        engineerNumber: '',
        workshopName: '',
        workshopNumber: '',
        engineerNote: '',
        stampNumber: '',
        notes: '',
        date: '',
        approvalState: '',
        isFound: false,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // withProcessNote — merges DataType:1 response
  // ---------------------------------------------------------------------------

  /// ## withProcessNote
  ///
  /// **SOAP Method**: `GetBiIllegalProcessNote`
  /// **SOAPAction**: `http://tempuri.org/IBillingWcfsrv/GetBiIllegalProcessNote`
  /// **Query DataType**: 1
  ///
  /// **Description**: Merges engineer, workshop, note, stamp, and date fields
  /// from the DataType:1 response into this model and returns a new instance.
  ///
  /// **Parameters**:
  /// - [xmlBody] — Raw SOAP response XML from the DataType:1 call.
  ///
  /// **Returns**: Updated [OperationModel] with all note fields populated,
  /// or `this` unchanged if the response has no rows.
  ///
  /// **Throws**: Never.
  OperationModel withProcessNote(String xmlBody) {
    try {
      final row = _findFirstRow(xmlBody);
      if (row == null) return this;

      return OperationModel(
        pid: pid,
        city: city,
        subscriptionNum: subscriptionNum,
        engineerName: _txt(row, 'ENG_EMP_NAME'),
        engineerNumber: _txt(row, 'ENG_EMP_NUMBER'),
        workshopName: _txt(row, 'WRK_NAME'),
        workshopNumber: _txt(row, 'WRK_NO'),
        engineerNote: _txt(row, 'ENG_ILL_NOTE'),
        stampNumber: _txt(row, 'STAMP_NUM'),
        notes: _txt(row, 'ILL_NOTES'),
        date: _txt(row, 'D'),
        approvalState: _txt(row, 'ENG_APP_APPROVAL_STATE'),
        isFound: isFound,
      );
    } catch (_) {
      return this;
    }
  }

  // ---------------------------------------------------------------------------
  // Shared XML helpers
  // ---------------------------------------------------------------------------

  static XmlElement? _findFirstRow(String xmlBody) {
    try {
      final document = XmlDocument.parse(xmlBody);
      final diffgram = document.descendants
          .whereType<XmlElement>()
          .where((e) => e.localName == 'diffgram')
          .firstOrNull;
      if (diffgram == null) return null;
      final dataSet = diffgram.childElements.firstOrNull;
      return dataSet?.childElements.firstOrNull;
    } catch (_) {
      return null;
    }
  }

  static String _txt(XmlElement el, String tag) {
    try {
      return el.childElements
          .firstWhere((c) => c.localName == tag)
          .innerText
          .trim();
    } catch (_) {
      return '';
    }
  }
}
