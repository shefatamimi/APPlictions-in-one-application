/// # InquiryRemoteDataSource
///
/// Remote data source for the subscription/meter inquiry feature.
///
/// Encapsulates all SOAP calls needed to search for a customer by meter number,
/// subscription number, or 10-digit combined key, plus city list retrieval.
///
/// Uses [RsaHelper] to encrypt each query payload before transmission,
/// exactly as the original `InquirActivity.java` did via `RSA.encrypt()`.
library;

import 'dart:developer' as dev;

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/network/soap_client.dart';
import '../../../../../core/utils/rsa_helper.dart';
import '../models/city_model.dart';
import '../models/customer_info_model.dart';

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

abstract class InquiryRemoteDataSource {
  /// Searches by meter serial → returns raw XML (DataType:31 response).
  Future<CustomerInfoModel> searchByMeter(String meterNum);

  /// Looks up the meter serial number for a subscription.
  /// Returns the meter serial string extracted from the DataType:12 response.
  Future<String> resolveMeterFromSubscription(
      String cityCode, String subSerial);

  /// Fetches extra subscription fields (DataType:13).
  /// Returns raw XML for merging into an existing [CustomerInfoModel].
  Future<String> fetchExtraInfo(String subscription10);

  /// Checks for an illegal notification on a subscription (DataType:18).
  /// Returns raw XML for [CustomerInfoModel.hasNotificationFromXml].
  Future<String> checkIllegalNotification(String subscription10);

  /// Fetches the list of cities (GetCityNumber).
  Future<List<CityModel>> getCities();
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class InquiryRemoteDataSourceImpl implements InquiryRemoteDataSource {
  final SoapClient _soap;

  const InquiryRemoteDataSourceImpl(this._soap);

  // ── searchByMeter ──────────────────────────────────────────────────────────

  /// ## searchByMeter
  ///
  /// **SOAP Method**: `GetCustomerBillingInfoEnc`
  /// **SOAPAction**: `http://tempuri.org/IBillingWcfsrv/GetCustomerBillingInfoEnc`
  /// **DataType**: 31
  ///
  /// **Description**: Encrypts and sends a DataType:31 query to fetch all
  /// customer and meter info for the given physical meter serial number.
  ///
  /// **Query format**:
  /// `DataType:31;Where:;mtrnum: and mtr.MTR_M_NUM = '{meterNum}'`
  ///
  /// **Parameters**:
  /// - [meterNum] — Physical meter serial number.
  ///
  /// **Returns**: Populated [CustomerInfoModel] (with extra info merged in).
  ///
  /// **Throws**: [Exception] if SOAP call fails or no valid meter row found.
  @override
  Future<CustomerInfoModel> searchByMeter(String meterNum) async {
    final query = "DataType:31;Where:;mtrnum: and mtr.MTR_M_NUM = '$meterNum'";
    final encrypted = RsaHelper.encrypt(query);

    dev.log('[InquiryDS] searchByMeter query: $query', name: 'Inquiry');

    final xmlBody = await _soap.call(
      methodName: AppConstants.inquiryMethodName,
      soapAction: AppConstants.inquirySoapAction,
      bodyProperties: {'data': encrypted},
    );

    dev.log('[InquiryDS] searchByMeter response length: ${xmlBody.length}',
        name: 'Inquiry');

    final model = CustomerInfoModel.fromMeterXml(xmlBody);
    if (model == null) {
      throw Exception('لم يتم العثور على عداد بالرقم المُدخل');
    }
    return model;
  }

  // ── resolveMeterFromSubscription ───────────────────────────────────────────

  /// ## resolveMeterFromSubscription
  ///
  /// **SOAP Method**: `GetCustomerBillingInfoEnc`
  /// **SOAPAction**: `http://tempuri.org/IBillingWcfsrv/GetCustomerBillingInfoEnc`
  /// **DataType**: 12
  ///
  /// **Description**: Resolves the physical meter serial number for a
  /// subscription identified by its city code and 7-digit serial.
  ///
  /// **Query format**:
  /// `DataType:12;Where: and LPAD(cmf.cusm_city,3,'0')||LPAD(cmf.CUSM_NUM,7,'0') = '{sub10}';mtrnum:{sub10}`
  ///
  /// **Parameters**:
  /// - [cityCode] — 3-digit city code.
  /// - [subSerial] — 7-digit subscription serial.
  ///
  /// **Returns**: The `MTR_M_NUM` string from the SOAP response.
  ///
  /// **Throws**: [Exception] if no meter number is found.
  @override
  Future<String> resolveMeterFromSubscription(
    String cityCode,
    String subSerial,
  ) async {
    final sub10 = cityCode.padLeft(3, '0') + subSerial.padLeft(7, '0');

    final query =
        "DataType:12;Where: and LPAD(cmf.cusm_city,3,'0')||LPAD(cmf.CUSM_NUM,7,'0') = '$sub10';mtrnum:$sub10";
    final encrypted = RsaHelper.encrypt(query);

    dev.log('[InquiryDS] resolveMeter query: $query', name: 'Inquiry');

    final xmlBody = await _soap.call(
      methodName: AppConstants.inquiryMethodName,
      soapAction: AppConstants.inquirySoapAction,
      bodyProperties: {'data': encrypted},
    );

    final row = CustomerInfoModel.findAllRows(xmlBody).firstOrNull;
    if (row == null)
      throw Exception('لم يتم العثور على اشتراك بالبيانات المُدخلة');

    final meterNum = CustomerInfoModel.readText(row, 'MTR_M_NUM');
    if (meterNum.isEmpty) {
      throw Exception('لم يتم العثور على عداد لهذا الإشتراك');
    }
    return meterNum;
  }

  // ── fetchExtraInfo ─────────────────────────────────────────────────────────

  /// ## fetchExtraInfo
  ///
  /// **SOAP Method**: `GetCustomerBillingInfoEnc`
  /// **SOAPAction**: `http://tempuri.org/IBillingWcfsrv/GetCustomerBillingInfoEnc`
  /// **DataType**: 13
  ///
  /// **Description**: Fetches supplementary subscription data (type, last
  /// reading, last reading date) for a given 10-digit subscription number.
  ///
  /// **Query format**:
  /// `DataType:13;Where: and LPAD(cmf.cusm_city,3,'0')||LPAD(cmf.CUSM_NUM,7,'0') = '{sub10}';mtrnum:`
  ///
  /// **Parameters**:
  /// - [subscription10] — Full 10-digit subscription string.
  ///
  /// **Returns**: Raw SOAP response XML for [CustomerInfoModel.withExtraInfo].
  ///
  /// **Throws**: [Exception] on network or SOAP error.
  @override
  Future<String> fetchExtraInfo(String subscription10) async {
    final query =
        "DataType:13;Where: and LPAD(cmf.cusm_city,3,'0')||LPAD(cmf.CUSM_NUM,7,'0') = '$subscription10';mtrnum:";
    final encrypted = RsaHelper.encrypt(query);

    return _soap.call(
      methodName: AppConstants.inquiryMethodName,
      soapAction: AppConstants.inquirySoapAction,
      bodyProperties: {'data': encrypted},
    );
  }

  // ── checkIllegalNotification ───────────────────────────────────────────────

  /// ## checkIllegalNotification
  ///
  /// **SOAP Method**: `GetIllegalNotification`
  /// **SOAPAction**: `http://tempuri.org/IBillingWcfsrv/GetIllegalNotification`
  /// **DataType**: 18
  ///
  /// **Description**: Queries whether an illegal notification (بلاغ) exists
  /// for the given 10-digit subscription number.
  ///
  /// **Query format**:
  /// `DataType:18;Where:  and LPAD(city_id,3,'0')||LPAD(cust_id,7,'0') = '{sub10}'`
  ///
  /// **Parameters**:
  /// - [subscription10] — Full 10-digit subscription string.
  ///
  /// **Returns**: Raw SOAP XML; caller uses
  /// [CustomerInfoModel.hasNotificationFromXml] to evaluate the result.
  ///
  /// **Throws**: [Exception] on network or SOAP error.
  @override
  Future<String> checkIllegalNotification(String subscription10) async {
    final query =
        "DataType:18;Where:  and LPAD(city_id,3,'0')||LPAD(cust_id,7,'0') = '$subscription10'";
    final encrypted = RsaHelper.encrypt(query);

    return _soap.call(
      methodName: AppConstants.illegalNotificationMethodName,
      soapAction: AppConstants.illegalNotificationSoapAction,
      bodyProperties: {'data': encrypted},
    );
  }

  // ── getCities ──────────────────────────────────────────────────────────────

  /// ## getCities
  ///
  /// **SOAP Method**: `GetCityNumber`
  /// **SOAPAction**: `http://tempuri.org/IBillingWcfsrv/GetCityNumber`
  ///
  /// **Description**: Fetches the complete list of city/town records to
  /// populate the inquiry screen's city-name autocomplete dropdown.
  ///
  /// **Query format**: `City:1,DataType:3`
  ///
  /// **Returns**: List of [CityModel] instances parsed from the response.
  ///
  /// **Throws**: [Exception] on network or SOAP error.
  @override
  Future<List<CityModel>> getCities() async {
    const query = 'City:1,DataType:3';
    final encrypted = RsaHelper.encrypt(query);

    dev.log('[InquiryDS] getCities', name: 'Inquiry');

    final xmlBody = await _soap.call(
      methodName: AppConstants.cityListMethodName,
      soapAction: AppConstants.cityListSoapAction,
      bodyProperties: {'data': encrypted},
    );

    return CityModel.fromXmlList(xmlBody);
  }
}
