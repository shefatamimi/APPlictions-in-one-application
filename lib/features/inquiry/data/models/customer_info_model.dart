/// # CustomerInfoModel
///
/// Data-layer model extending [CustomerInfoEntity] with SOAP XML parsing logic.
///
/// ## SOAP Calls Handled
///
/// 1. **DataType:31** — Primary meter info
///    Action: `GetCustomerBillingInfoEnc`
///    Query: `DataType:31;Where:;mtrnum: and mtr.MTR_M_NUM = '{meterNum}'`
///    Fields: CTYM_NAME, CUSM_NAME, MTR_NUM, MTR_CITY, SMART, KIND, MODEL,
///            ADDRESS, MTR_M_NUM, FAZ, C_KIND, POS_X, POS_Y, MOBILE_NO,
///            REGM_CODE, RDRM_NAME, CUSM_COSTTIME_FLAG,
///            CUSM_REN_LREAD_PARTIAL_PEAK … (8 ToU fields)
///
/// 2. **DataType:13** — Extra subscription info
///    Action: `GetCustomerBillingInfoEnc`
///    Query: `DataType:13;Where: and LPAD(...)... = '{sub}';mtrnum:`
///    Fields: CUSM_KIND, CUSM_M_LREAD, CUSM_M_LDATE
///
/// The two responses are merged into a single [CustomerInfoModel] instance by
/// the data source before being returned to the repository.
library;

import 'package:xml/xml.dart';

import '../../domain/entities/customer_info_entity.dart';

class CustomerInfoModel extends CustomerInfoEntity {
  const CustomerInfoModel({
    required super.customerName,
    required super.subscriptionSerial,
    required super.cityCode,
    required super.cityName,
    required super.address,
    required super.meterKind,
    required super.meterModel,
    required super.meterSerialNum,
    required super.isSmart,
    required super.phase,
    required super.subscriptionKind,
    required super.subscriptionType,
    required super.lastReading,
    required super.lastReadingDate,
    required super.supportPhone,
    required super.regionCode,
    required super.readerName,
    super.posX,
    super.posY,
    required super.hasTimeOfUse,
    required super.timeReadings,
    super.hasIllegalNotification,
  });

  // ---------------------------------------------------------------------------
  // fromMeterXml — parses DataType:31 response
  // ---------------------------------------------------------------------------

  /// ## fromMeterXml
  ///
  /// **SOAP Method**: `GetCustomerBillingInfoEnc`
  /// **Query DataType**: `31`
  /// **SOAP Action**: `http://tempuri.org/IBillingWcfsrv/GetCustomerBillingInfoEnc`
  ///
  /// **Description**: Parses the raw SOAP XML body returned by the DataType:31
  /// (meter-number lookup) call and extracts all customer/meter fields into a
  /// [CustomerInfoModel].
  ///
  /// Uses two fallback strategies (structural diffgram navigation, then
  /// any-row scan) to handle namespace variations in the .NET DataSet response.
  ///
  /// **Parameters**:
  /// - [xmlBody] — Raw SOAP response XML string.
  ///
  /// **Returns**: Populated [CustomerInfoModel], or `null` if no valid row
  /// found (empty `MTR_M_NUM`).
  ///
  /// **Throws**: Never — XML parse errors return `null`.
  static CustomerInfoModel? fromMeterXml(String xmlBody) {
    try {
      final row = _findFirstRow(xmlBody);
      if (row == null) return null;

      final meterSerial = _txt(row, 'MTR_M_NUM');
      if (meterSerial.isEmpty || meterSerial == '-1') return null;

      final costTimeFlag = _txt(row, 'CUSM_COSTTIME_FLAG');
      final hasToU = costTimeFlag == '1';

      final List<String> timeReadings = hasToU
          ? [
              _txt(row, 'CUSM_PREAD_PEAK_TIME'),
              _txt(row, 'CUSM_PREAD_OFFPEAK_TIME'),
              _txt(row, 'CUSM_REN_LREAD_PARTIAL_PEAK2'),
              _txt(row, 'CUSM_REN_LREAD_PARTIAL_PEAK3'),
              _txt(row, 'CUSM_REN_LREAD_PARTIAL_OFFPEAK2'),
              _txt(row, 'CUSM_REN_LREAD_PARTIAL_OFFPEAK3'),
              _txt(row, 'CUSM_PREAD_EXP_PEAK_TIME'),
              _txt(row, 'CUSM_PREAD_EXP_OFFPEAK_TIME'),
            ]
          : [];

      final smart = _txt(row, 'SMART');

      return CustomerInfoModel(
        customerName: _txt(row, 'CUSM_NAME'),
        subscriptionSerial: _txt(row, 'MTR_NUM'),
        cityCode: _txt(row, 'MTR_CITY'),
        cityName: _txt(row, 'CTYM_NAME'),
        address: _txt(row, 'ADDRESS'),
        meterKind: _txt(row, 'KIND'),
        meterModel: _txt(row, 'MODEL'),
        meterSerialNum: meterSerial,
        isSmart: smart == '1',
        phase: _txt(row, 'FAZ'),
        subscriptionKind: _txt(row, 'C_KIND'),
        subscriptionType: '',
        lastReading: '',
        lastReadingDate: '',
        supportPhone: _txt(row, 'MOBILE_NO'),
        regionCode: _txt(row, 'REGM_CODE'),
        readerName: _txt(row, 'RDRM_NAME'),
        posX: _txtNullable(row, 'POS_X'),
        posY: _txtNullable(row, 'POS_Y'),
        hasTimeOfUse: hasToU,
        timeReadings: timeReadings,
      );
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // withExtraInfo — merges DataType:13 fields into an existing model
  // ---------------------------------------------------------------------------

  /// ## withExtraInfo
  ///
  /// **SOAP Method**: `GetCustomerBillingInfoEnc`
  /// **Query DataType**: `13`
  ///
  /// **Description**: Parses the DataType:13 (extra subscription info) SOAP
  /// response and returns a new [CustomerInfoModel] with the additional fields
  /// (`subscriptionType`, `lastReading`, `lastReadingDate`) merged in.
  ///
  /// **Parameters**:
  /// - [xmlBody] — Raw SOAP response XML from the DataType:13 call.
  ///
  /// **Returns**: Updated [CustomerInfoModel] with extra fields populated,
  /// or `this` unchanged if the response cannot be parsed.
  ///
  /// **Throws**: Never.
  CustomerInfoModel withExtraInfo(String xmlBody) {
    try {
      final row = _findFirstRow(xmlBody);
      if (row == null) return this;

      return CustomerInfoModel(
        customerName: customerName,
        subscriptionSerial: subscriptionSerial,
        cityCode: cityCode,
        cityName: cityName,
        address: address,
        meterKind: meterKind,
        meterModel: meterModel,
        meterSerialNum: meterSerialNum,
        isSmart: isSmart,
        phase: phase,
        subscriptionKind: subscriptionKind,
        subscriptionType: _txt(row, 'CUSM_KIND'),
        lastReading: _txt(row, 'CUSM_M_LREAD'),
        lastReadingDate: _txt(row, 'CUSM_M_LDATE'),
        supportPhone: supportPhone,
        regionCode: regionCode,
        readerName: readerName,
        posX: posX,
        posY: posY,
        hasTimeOfUse: hasTimeOfUse,
        timeReadings: timeReadings,
        hasIllegalNotification: hasIllegalNotification,
      );
    } catch (_) {
      return this;
    }
  }

  // ---------------------------------------------------------------------------
  // hasNotification — checks DataType:18 response for an illegal notification
  // ---------------------------------------------------------------------------

  /// ## hasNotificationFromXml
  ///
  /// **SOAP Method**: `GetIllegalNotification`
  /// **Query**: `DataType:18;Where: and LPAD(city_id,3,'0')||LPAD(cust_id,7,'0') = '{sub}'`
  ///
  /// **Description**: Returns `true` if the DataType:18 response contains at
  /// least one row (i.e. an illegal notification exists for this subscription).
  ///
  /// **Parameters**:
  /// - [xmlBody] — Raw SOAP XML response.
  ///
  /// **Returns**: `true` if a notification exists, `false` otherwise.
  ///
  /// **Throws**: Never.
  static bool hasNotificationFromXml(String xmlBody) {
    try {
      final row = _findFirstRow(xmlBody);
      if (row == null) return false;
      final id = _txt(row, 'ID');
      return id.isNotEmpty && id != '-1';
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Shared XML helpers
  // ---------------------------------------------------------------------------

  /// Finds the first data row inside the .NET DataSet diffgram response.
  ///
  /// Strategy 1: Body → diffgram → NewDataSet → first row element.
  /// Strategy 2: Any diffgram anywhere in the document.
  static XmlElement? _findFirstRow(String xmlBody) {
    final document = XmlDocument.parse(xmlBody);

    // Strategy 1: navigate via SOAP Body
    final body = document.descendants
        .whereType<XmlElement>()
        .where((e) => e.localName == 'Body')
        .firstOrNull;

    if (body != null) {
      final diffgram = body.descendants
          .whereType<XmlElement>()
          .where((e) => e.localName == 'diffgram')
          .firstOrNull;
      if (diffgram != null) {
        final dataSet = diffgram.childElements.firstOrNull;
        final row = dataSet?.childElements.firstOrNull;
        if (row != null) return row;
      }
    }

    // Strategy 2: scan the whole document for diffgram
    final diffgram = document.descendants
        .whereType<XmlElement>()
        .where((e) => e.localName == 'diffgram')
        .firstOrNull;
    if (diffgram != null) {
      final dataSet = diffgram.childElements.firstOrNull;
      return dataSet?.childElements.firstOrNull;
    }

    return null;
  }

  /// Returns all data rows from the diffgram (for list responses).
  static List<XmlElement> _findAllRows(String xmlBody) {
    try {
      final document = XmlDocument.parse(xmlBody);
      final diffgram = document.descendants
          .whereType<XmlElement>()
          .where((e) => e.localName == 'diffgram')
          .firstOrNull;
      if (diffgram == null) return [];
      final dataSet = diffgram.childElements.firstOrNull;
      return dataSet?.childElements.toList() ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Extracts trimmed text of a child element by localName.
  /// Returns empty string on any failure.
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

  /// Like [_txt] but returns `null` instead of empty string when not found.
  static String? _txtNullable(XmlElement el, String tag) {
    try {
      final v = el.childElements
          .firstWhere((c) => c.localName == tag)
          .innerText
          .trim();
      return v.isEmpty ? null : v;
    } catch (_) {
      return null;
    }
  }

  // Expose _findAllRows publicly for CityModel re-use
  static List<XmlElement> findAllRows(String xmlBody) => _findAllRows(xmlBody);

  // Expose _txt publicly for CityModel re-use
  static String readText(XmlElement el, String tag) => _txt(el, tag);
}
