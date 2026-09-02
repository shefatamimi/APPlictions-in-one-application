/// # InspectionInquiryRemoteDataSource
///
/// Remote data source for the inspection process note screen.
///
/// Encapsulates SOAP calls for operation lookup (two chained calls) and the
/// engineer list fetch. All payloads are RSA-encrypted before transmission.
library;

import 'dart:developer' as dev;

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/network/soap_client.dart';
import '../../../../../core/utils/rsa_helper.dart';
import '../models/engineer_model.dart';
import '../models/operation_model.dart';

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

abstract class InspectionInquiryRemoteDataSource {
  /// Fetches workflow transactions for the given PID (DataType:2).
  Future<OperationModel> getWfTransaction(String pid);

  /// Fetches process note data for the given PID (DataType:1).
  Future<String> getProcessNoteXml(String pid);

  /// Fetches the list of engineers (DataType:73).
  Future<List<EngineerModel>> getEngineers();

  /// Saves the process note (InsertIllegalProcessNote).
  Future<String> insertProcessNote({
    required String data,
    required String? base64Image,
  });

  /// Fetches helper workshops (GetIDECO_WorkshopMF).
  Future<List<EngineerModel>> getHelperWorkshops();
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class InspectionInquiryRemoteDataSourceImpl
    implements InspectionInquiryRemoteDataSource {
  final SoapClient _soap;

  const InspectionInquiryRemoteDataSourceImpl(this._soap);

  // ── getWfTransaction ───────────────────────────────────────────────────────

  /// ## getWfTransaction
  ///
  /// **SOAP Method**: `GetWFTRANSACTIONSBiIllegalProcessNote`
  /// **SOAPAction**: `http://tempuri.org/IBillingWcfsrv/GetWFTRANSACTIONSBiIllegalProcessNote`
  ///
  /// **Description**: Retrieves workflow transaction details for an illegal
  /// process by its main PID, returning city and subscription number.
  ///
  /// **Query format**: `DataType:2;Where: and t.MAIN_PID = {pid}`
  ///
  /// **Parameters**:
  /// - [pid] — Numeric operation identifier.
  ///
  /// **Returns**: Partially populated [OperationModel] (city + subscriptionNum).
  ///
  /// **Throws**: [Exception] on network or SOAP error.
  @override
  Future<OperationModel> getWfTransaction(String pid) async {
    final query = 'DataType:2;Where: and t.MAIN_PID = $pid';
    final encrypted = RsaHelper.encrypt(query);

    dev.log('[InspectionDS] getWfTransaction pid: $pid', name: 'Inspection');

    final xmlBody = await _soap.call(
      methodName: AppConstants.wfTransactionMethodName,
      soapAction: AppConstants.wfTransactionSoapAction,
      bodyProperties: {'data': encrypted},
    );

    dev.log('[InspectionDS] wfTransaction response length: ${xmlBody.length}',
        name: 'Inspection');

    return OperationModel.fromWfXml(xmlBody, pid);
  }

  // ── getProcessNoteXml ──────────────────────────────────────────────────────

  /// ## getProcessNoteXml
  ///
  /// **SOAP Method**: `GetBiIllegalProcessNote`
  /// **SOAPAction**: `http://tempuri.org/IBillingWcfsrv/GetBiIllegalProcessNote`
  ///
  /// **Description**: Fetches the process note record for a PID, including
  /// engineer info, workshop, stamp, notes, and approval state.
  ///
  /// **Query format**: `DataType:1;strWhereOracle:  and n.pid={pid}`
  ///
  /// **Parameters**:
  /// - [pid] — Numeric operation identifier.
  ///
  /// **Returns**: Raw SOAP response XML for merging via
  /// [OperationModel.withProcessNote].
  ///
  /// **Throws**: [Exception] on network or SOAP error.
  @override
  Future<String> getProcessNoteXml(String pid) async {
    final query = 'DataType:1;strWhereOracle:  and n.pid=$pid';
    final encrypted = RsaHelper.encrypt(query);

    return _soap.call(
      methodName: AppConstants.processNoteMethodName,
      soapAction: AppConstants.processNoteSoapAction,
      bodyProperties: {'data': encrypted},
    );
  }

  // ── getEngineers ───────────────────────────────────────────────────────────

  /// ## getEngineers
  ///
  /// **SOAP Method**: `GetGenericsDataTable`
  /// **SOAPAction**: `http://tempuri.org/IBillingWcfsrv/GetGenericsDataTable`
  ///
  /// **Description**: Fetches the full list of engineer records (employee
  /// number + name) to populate the engineer autocomplete dropdown.
  ///
  /// **Query format**: `DataType:73,Major:721`
  ///
  /// **Returns**: List of [EngineerModel] instances.
  ///
  /// **Throws**: [Exception] on network or SOAP error.
  @override
  Future<List<EngineerModel>> getEngineers() async {
    const query = 'DataType:73,Major:721';
    final encrypted = RsaHelper.encrypt(query);

    dev.log('[InspectionDS] getEngineers', name: 'Inspection');

    final xmlBody = await _soap.call(
      methodName: AppConstants.engineerListMethodName,
      soapAction: AppConstants.engineerListSoapAction,
      bodyProperties: {'data': encrypted},
    );

    return EngineerModel.fromXmlList(xmlBody);
  }

  // ── insertProcessNote ──────────────────────────────────────────────────────

  /// ## insertProcessNote
  ///
  /// **SOAP Method**: `InsertIllegalProcessNote`
  /// **SOAPAction**: `http://tempuri.org/IBillingWcfsrv/InsertIllegalProcessNote`
  ///
  /// **Description**: Commits the illegal process note to the server. The
  /// [data] string (concatenated semicolon-separated fields) is RSA-encrypted
  /// before being sent as the `data` property. The [base64Image] is sent
  /// as the `image` property.
  @override
  Future<String> insertProcessNote({
    required String data,
    required String? base64Image,
  }) async {
    final encrypted = RsaHelper.encrypt(data);

    return _soap.call(
      methodName: AppConstants.insertProcessNoteMethodName,
      soapAction: AppConstants.insertProcessNoteSoapAction,
      bodyProperties: {
        'data': encrypted,
        'image': base64Image ?? '',
      },
    );
  }

  // ── getHelperWorkshops ─────────────────────────────────────────────────────

  /// ## getHelperWorkshops
  ///
  /// **SOAP Method**: `GetIDECO_WorkshopMF`
  ///
  /// **Description**: Fetches the list of helper workshops.
  /// **Query**: `wrk_type:8,office_id:0,minor:0,datatype:3`
  @override
  Future<List<EngineerModel>> getHelperWorkshops() async {
    const query = 'wrk_type:8,office_id:0,minor:0,datatype:3';
    final encrypted = RsaHelper.encrypt(query);

    final xmlBody = await _soap.call(
      methodName: AppConstants.helperWorkshopMethodName,
      soapAction: AppConstants.helperWorkshopSoapAction,
      bodyProperties: {'data': encrypted},
    );

    // Reusing EngineerModel for simple label/value pairs (Workshop ID / Name)
    return EngineerModel.fromXmlList(xmlBody,
        idTag: 'WRK_NO', nameTag: 'WRK_NAME');
  }
}
