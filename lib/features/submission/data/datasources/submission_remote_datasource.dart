/// # SubmissionRemoteDataSource
///
/// Remote data source for the "إستعلام بلاغات" (submission inquiry) screen.
/// Calls `GetIllegalNotification` with DataType:18 filtered by workshop ID.
library;

import 'dart:developer' as dev;

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/network/soap_client.dart';
import '../../../../../core/utils/rsa_helper.dart';
import '../models/submission_model.dart';

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

abstract class SubmissionRemoteDataSource {
  /// Fetches all illegal-notification records for [workshopId].
  Future<List<SubmissionModel>> getSubmissions(String workshopId);
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class SubmissionRemoteDataSourceImpl implements SubmissionRemoteDataSource {
  final SoapClient _soap;
  const SubmissionRemoteDataSourceImpl(this._soap);

  // ── getSubmissions ─────────────────────────────────────────────────────────

  /// ## getSubmissions
  ///
  /// **SOAP Method**: `GetIllegalNotification`
  /// **SOAPAction**: `http://tempuri.org/IBillingWcfsrv/GetIllegalNotification`
  ///
  /// **Description**: Retrieves all illegal-notification records that belong
  /// to the given workshop (WORKSHOP_ID), allowing the engineer to review
  /// their assigned notifications and take action on each one.
  ///
  /// **Query format**: `DataType:18;Where: and WORKSHOP_ID = {workshopId}`
  ///
  /// **Parameters**:
  /// - [workshopId] — The logged-in user's workshop identifier
  ///   (from `Employee.workshopNumber`).
  ///
  /// **Returns**: List of [SubmissionModel] instances parsed from the
  /// SOAP XML response.
  ///
  /// **Throws**: [Exception] on network or SOAP error.
  @override
  Future<List<SubmissionModel>> getSubmissions(String workshopId) async {
    final query = 'DataType:18;Where: and WORKSHOP_ID = $workshopId';
    final encrypted = RsaHelper.encrypt(query);

    dev.log('[SubmissionDS] getSubmissions workshopId: $workshopId',
        name: 'Submission');

    final xmlBody = await _soap.call(
      methodName: AppConstants.illegalNotificationMethodName,
      soapAction: AppConstants.illegalNotificationSoapAction,
      bodyProperties: {'data': encrypted},
    );

    dev.log('[SubmissionDS] response length: ${xmlBody.length}',
        name: 'Submission');

    return SubmissionModel.fromXmlList(xmlBody);
  }
}
