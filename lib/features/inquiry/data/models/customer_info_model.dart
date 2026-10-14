/// # CustomerInfoModel
///
/// Data-layer model extending [CustomerInfoEntity] with SOAP XML parsing logic.
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
    super.lastInspectionDate,
    super.lastVisitDate,
    super.supportProviderName,
    super.meterStatus,
    super.loadProfile,
    required super.hasTimeOfUse,
    required super.isRenewable,
    required super.timeReadings,
    super.hasIllegalNotification,
  });

  static CustomerInfoModel? fromMeterXml(String xmlBody) {
    try {
      final row = _findFirstRow(xmlBody);
      if (row == null) return null;

      final meterSerial = _txt(row, 'MTR_M_NUM');
      if (meterSerial.isEmpty || meterSerial == '-1') return null;

      final costTimeFlag = _txt(row, 'CUSM_COSTTIME_FLAG');
      final hasToU = costTimeFlag == '1';

      final ren = _txt(row, 'REN');
      final isRenewable = ren == '1';

      final List<String> timeReadings = hasToU
          ? [
              _txt(row, 'CUSM_PREAD_PEAK_TIME'),
              _txt(row, 'CUSM_PREAD_OUT_PEAK_TIME'),
              _txt(row, 'CUSM_PREAD_PARTIAL_PEAK1'),
              _txt(row, 'CUSM_PREAD_PARTIAL_PEAK2'),
              _txt(row, 'CUSM_LREAD_PEAK_TIME'),
              _txt(row, 'CUSM_LREAD_OUT_PEAK_TIME'),
              _txt(row, 'CUSM_LREAD_PARTIAL_PEAK1'),
              _txt(row, 'CUSM_LREAD_PARTIAL_PEAK2'),
            ]
          : [];

      final smart = _txt(row, 'SMART');
      final mStatus = _txt(row, 'MTR_STATUS');

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
        lastInspectionDate: _txt(row, 'LAST_INSP_DATE'),
        lastVisitDate: _txt(row, 'LAST_VISIT_DATE'),
        supportProviderName: _txt(row, 'SUPPORT_NAME'),
        meterStatus: mStatus.isEmpty ? 'Connected' : mStatus,
        loadProfile: _txt(row, 'LOAD_PROFILE'),
        hasTimeOfUse: hasToU,
        isRenewable: isRenewable,
        timeReadings: timeReadings,
      );
    } catch (_) {
      return null;
    }
  }

  CustomerInfoModel withExtraInfo(String xmlBody) {
    try {
      final row = _findFirstRow(xmlBody);
      if (row == null) return this;

      final subType = _txt(row, 'CUSM_KIND');
      final lRead = _txt(row, 'CUSM_M_LREAD');
      final lDate = _txt(row, 'CUSM_M_LDATE');
      final mob = _txt(row, 'MOBILE_NO');
      final reg = _txt(row, 'REGM_CODE');
      final rdr = _txt(row, 'RDRM_NAME');
      final inspDate = _txt(row, 'LAST_INSP_DATE');
      final visitDate = _txt(row, 'LAST_VISIT_DATE');
      final suppName = _txt(row, 'SUPPORT_NAME');
      final mStatus = _txt(row, 'MTR_STATUS');
      final lProfile = _txt(row, 'LOAD_PROFILE');

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
        subscriptionType: subType.isNotEmpty ? subType : subscriptionType,
        lastReading: lRead.isNotEmpty ? lRead : lastReading,
        lastReadingDate: lDate.isNotEmpty ? lDate : lastReadingDate,
        supportPhone: mob.isNotEmpty ? mob : supportPhone,
        regionCode: reg.isNotEmpty ? reg : regionCode,
        readerName: rdr.isNotEmpty ? rdr : readerName,
        posX: posX,
        posY: posY,
        lastInspectionDate: inspDate.isNotEmpty ? inspDate : lastInspectionDate,
        lastVisitDate: visitDate.isNotEmpty ? visitDate : lastVisitDate,
        supportProviderName: suppName.isNotEmpty ? suppName : supportProviderName,
        meterStatus: mStatus.isNotEmpty ? mStatus : meterStatus,
        loadProfile: lProfile.isNotEmpty ? lProfile : loadProfile,
        hasTimeOfUse: hasTimeOfUse,
        isRenewable: isRenewable,
        timeReadings: timeReadings,
        hasIllegalNotification: hasIllegalNotification,
      );
    } catch (_) {
      return this;
    }
  }

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

  static XmlElement? _findFirstRow(String xmlBody) {
    final document = XmlDocument.parse(xmlBody);

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

  static List<XmlElement> findAllRows(String xmlBody) => _findAllRows(xmlBody);
  static String readText(XmlElement el, String tag) => _txt(el, tag);
}
