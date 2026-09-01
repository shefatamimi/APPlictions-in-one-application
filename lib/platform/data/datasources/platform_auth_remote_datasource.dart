/// # PlatformAuthRemoteDataSource
///
/// Single sign-on against the **existing** IDECO WCF service. No new endpoint,
/// no new column, no server-side change.
///
/// ## How permissions are discovered
///
/// The legacy login query already contains the application filter:
///
/// ```
/// DataType:<n>,Where: and A.USER_NAME='<user>'
///   and A.USR_DFN_PASSWORD='<pass>' and b.app_id = <serverAppId>
/// ```
///
/// The join behind `b.app_id` is the company's own application-permission
/// table, so the server — not the client — decides the answer:
///
/// * row(s) returned → the employee is entitled to that application;
/// * empty result    → wrong credentials **or** no entitlement.
///
/// The platform therefore issues one such query per registered [AppModule]
/// (concurrently, on the single shared endpoint) and treats the set of
/// non-empty answers as the authorised application list. Each query is
/// byte-for-byte what the corresponding standalone app sends today, so the
/// backend cannot tell the difference.
library;

import 'dart:developer' as developer;

import '../../../core/constants/app_constants.dart';
import '../../../core/network/soap_client.dart';
import '../../../core/utils/rsa_helper.dart';
import '../../domain/entities/app_module.dart';
import '../models/employee_model.dart';

abstract class PlatformAuthRemoteDataSource {
  /// ## probeModule
  ///
  /// **SOAP Method**: `GetAppLoginUser`
  /// **SOAP Action**: `http://tempuri.org/IBillingWcfsrv/GetAppLoginUser`
  /// **Endpoint**: `https://ideco.com.jo/IDECO_API_PROD/IdecoWcfsrv.svc`
  ///
  /// **Description**: Authenticates [username] / [password] for the single
  /// application described by [module].
  ///
  /// **Request payload** (RSA/PKCS1 encrypted, then Base64, sent as `data`):
  /// ```
  /// DataType:<module.loginDataType>,Where: and A.USER_NAME='<username>'
  ///   and A.USR_DFN_PASSWORD='<password>' and b.app_id = <module.serverAppId>
  /// ```
  ///
  /// **Returns**: the employee row when the module is authorised, `null` when
  /// the service returns an empty result set.
  ///
  /// **Throws**: [Exception] on HTTP / SOAP / encryption failure — mapped to a
  /// [Failure] by the repository.
  Future<EmployeeModel?> probeModule({
    required AppModule module,
    required String username,
    required String password,
  });
}

class PlatformAuthRemoteDataSourceImpl implements PlatformAuthRemoteDataSource {
  final SoapClient _soapClient;

  const PlatformAuthRemoteDataSourceImpl(this._soapClient);

  @override
  Future<EmployeeModel?> probeModule({
    required AppModule module,
    required String username,
    required String password,
  }) async {
    // Identical to the query the standalone applications already send —
    // only DataType and app_id vary, and both come from the registry.
    final plainQuery = "DataType:${module.loginDataType},"
        "Where: and A.USER_NAME='$username'"
        " and A.USR_DFN_PASSWORD='$password'"
        " and b.app_id = ${module.serverAppId}";

    final encrypted = RsaHelper.encrypt(plainQuery);

    final responseXml = await _soapClient.call(
      methodName: AppConstants.loginMethodName,
      soapAction: AppConstants.loginSoapAction,
      bodyProperties: {'data': encrypted},
    );

    final employee = EmployeeModel.fromXml(responseXml);

    developer.log(
      'GetAppLoginUser(app_id=${module.serverAppId}) → '
      '${employee == null ? 'not authorised' : 'authorised'}',
      name: 'PlatformAuth',
    );

    return employee;
  }
}
